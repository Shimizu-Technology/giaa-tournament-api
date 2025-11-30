module Api
  module V1
    class CheckoutController < BaseController
      skip_before_action :authenticate_admin!

      # POST /api/v1/checkout
      # Create a Stripe checkout session for a golfer (or simulate in test mode)
      def create
        golfer = Golfer.find(params[:golfer_id])

        # Ensure golfer hasn't already paid
        if golfer.payment_status == "paid"
          render json: { error: "Golfer has already paid" }, status: :unprocessable_entity
          return
        end

        setting = Setting.instance

        # TEST MODE: Simulate payment without Stripe
        if setting.test_mode?
          return handle_test_mode_checkout(golfer, setting)
        end

        # PRODUCTION MODE: Real Stripe checkout
        unless setting.stripe_secret_key.present?
          render json: { error: "Stripe is not configured. Please contact the administrator." }, status: :service_unavailable
          return
        end

        # Set Stripe API key from settings
        Stripe.api_key = setting.stripe_secret_key

        # Get the frontend URL for success/cancel redirects
        frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
        
        # Entry fee in cents from settings (default $125.00 = 12500 cents)
        entry_fee = setting.tournament_entry_fee || 12500

        begin
          # Create a Stripe Checkout Session
          session = Stripe::Checkout::Session.create({
            payment_method_types: ["card"],
            line_items: [{
              price_data: {
                currency: "usd",
                product_data: {
                  name: "#{setting.tournament_title || 'Golf Tournament'} Entry Fee",
                  description: "#{setting.tournament_name || 'Golf Tournament'} - #{golfer.name}",
                },
                unit_amount: entry_fee,
              },
              quantity: 1,
            }],
            mode: "payment",
            success_url: "#{frontend_url}/payment/success?session_id={CHECKOUT_SESSION_ID}",
            cancel_url: "#{frontend_url}/payment/cancel?golfer_id=#{golfer.id}",
            customer_email: golfer.email,
            metadata: {
              golfer_id: golfer.id.to_s,
              golfer_name: golfer.name,
              golfer_email: golfer.email,
            },
            # Collect billing address
            billing_address_collection: "required",
          })

          # Save the session ID to the golfer record
          golfer.update!(stripe_checkout_session_id: session.id)

          render json: {
            checkout_url: session.url,
            session_id: session.id,
            golfer_id: golfer.id,
            test_mode: false,
          }
        rescue Stripe::StripeError => e
          Rails.logger.error("Stripe error: #{e.message}")
          render json: { error: "Payment processing error: #{e.message}" }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/checkout/embedded
      # Create a checkout session for embedded checkout (golfer not created yet)
      def create_embedded
        setting = Setting.instance
        tournament = Tournament.current

        unless tournament&.can_register?
          render json: { error: "Registration is currently closed." }, status: :unprocessable_entity
          return
        end

        # Validate required fields
        golfer_data = params[:golfer]
        unless golfer_data[:name].present? && golfer_data[:email].present? && golfer_data[:phone].present?
          render json: { error: "Name, email, and phone are required" }, status: :unprocessable_entity
          return
        end

        # Check if email already registered for this tournament
        if tournament.golfers.exists?(email: golfer_data[:email])
          render json: { error: "This email is already registered for this tournament" }, status: :unprocessable_entity
          return
        end

        # TEST MODE: Return a simulated embedded session
        if setting.test_mode?
          return handle_test_mode_embedded(golfer_data, tournament)
        end

        # PRODUCTION MODE: Real Stripe embedded checkout
        unless setting.stripe_secret_key.present?
          render json: { error: "Stripe is not configured. Please contact the administrator." }, status: :service_unavailable
          return
        end

        Stripe.api_key = setting.stripe_secret_key
        frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:5173")
        entry_fee = tournament.entry_fee || 12500

        begin
          # Create a Stripe Checkout Session for embedded checkout
          session = Stripe::Checkout::Session.create({
            ui_mode: "embedded",
            payment_method_types: ["card"],
            line_items: [{
              price_data: {
                currency: "usd",
                product_data: {
                  name: "#{tournament.name} Entry Fee",
                  description: "Golf Tournament Registration - #{golfer_data[:name]}",
                },
                unit_amount: entry_fee,
              },
              quantity: 1,
            }],
            mode: "payment",
            return_url: "#{frontend_url}/registration/success?session_id={CHECKOUT_SESSION_ID}",
            customer_email: golfer_data[:email],
            metadata: {
              # Store all golfer data to create record after payment
              tournament_id: tournament.id.to_s,
              golfer_name: golfer_data[:name],
              golfer_email: golfer_data[:email],
              golfer_phone: golfer_data[:phone],
              golfer_mobile: golfer_data[:mobile] || "",
              golfer_company: golfer_data[:company] || "",
              golfer_address: golfer_data[:address] || "",
              waiver_accepted: "true",
              payment_type: "stripe",
            },
            billing_address_collection: "required",
          })

          render json: {
            client_secret: session.client_secret,
            session_id: session.id,
            test_mode: false,
          }
        rescue Stripe::StripeError => e
          Rails.logger.error("Stripe embedded checkout error: #{e.message}")
          render json: { error: "Payment processing error: #{e.message}" }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/checkout/confirm
      # Called after successful payment - verifies with Stripe and creates/updates golfer
      def confirm
        session_id = params[:session_id]

        unless session_id.present?
          render json: { error: "Session ID is required" }, status: :bad_request
          return
        end

        setting = Setting.instance

        # Handle test mode confirmation
        if session_id.start_with?("test_session_") || session_id.start_with?("test_embedded_")
          return handle_test_mode_confirm(session_id)
        end
        
        unless setting.stripe_secret_key.present?
          render json: { error: "Stripe is not configured" }, status: :service_unavailable
          return
        end

        Stripe.api_key = setting.stripe_secret_key

        begin
          # Retrieve the session from Stripe to verify payment
          session = Stripe::Checkout::Session.retrieve(session_id)

          # Check if payment was successful first
          unless session.payment_status == "paid"
            render json: {
              success: false,
              payment_status: session.payment_status,
              message: "Payment has not been completed yet"
            }, status: :payment_required
            return
          end

          # Find the golfer by session ID (for legacy redirect flow)
          golfer = Golfer.find_by(stripe_checkout_session_id: session_id)

          # If no golfer exists, this is from embedded checkout - create from metadata
          unless golfer
            golfer = create_golfer_from_session(session)
          end

          unless golfer
            render json: { error: "Could not find or create golfer for this session" }, status: :unprocessable_entity
            return
          end

          # Skip if already marked as paid (idempotency)
          if golfer.payment_status == "paid" && golfer.stripe_payment_intent_id.present?
            render json: {
              success: true,
              golfer: GolferSerializer.new(golfer),
              message: "Payment already confirmed!"
            }
            return
          end

          # Payment was successful - update golfer
            # Get the payment intent ID for record keeping
            payment_intent_id = session.payment_intent

            # Update golfer payment status
            golfer.update!(
              payment_status: "paid",
              stripe_payment_intent_id: payment_intent_id,
              payment_method: "stripe",
              payment_notes: "Paid via Stripe on #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
            )

            # Send registration confirmation email (since it was delayed for Stripe payments)
            GolferMailer.confirmation_email(golfer).deliver_later
            
            # Send payment confirmation email
            GolferMailer.payment_confirmation_email(golfer).deliver_later

            # Notify admin of new registration AND payment
            AdminMailer.notify_new_golfer(golfer).deliver_later
            AdminMailer.notify_payment_received(golfer).deliver_later

            # Broadcast update
            ActionCable.server.broadcast("golfers_channel", {
              action: "payment_confirmed",
              golfer: GolferSerializer.new(golfer).as_json
            })

            render json: {
              success: true,
              golfer: GolferSerializer.new(golfer),
              message: "Payment confirmed successfully!"
            }
        rescue Stripe::StripeError => e
          Rails.logger.error("Stripe verification error: #{e.message}")
          render json: { error: "Unable to verify payment: #{e.message}" }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/checkout/session/:session_id
      # Check the status of a checkout session
      def session_status
        session_id = params[:session_id]

        setting = Setting.instance
        return render json: { error: "Stripe not configured" }, status: :service_unavailable unless setting.stripe_secret_key.present?

        Stripe.api_key = setting.stripe_secret_key

        begin
          session = Stripe::Checkout::Session.retrieve(session_id)
          golfer = Golfer.find_by(stripe_checkout_session_id: session_id)

          render json: {
            session_id: session.id,
            payment_status: session.payment_status,
            status: session.status,
            golfer_id: golfer&.id,
            golfer_name: golfer&.name,
            amount_total: session.amount_total,
          }
        rescue Stripe::StripeError => e
          render json: { error: e.message }, status: :not_found
        end
      end

      private

      # Create a golfer from Stripe session metadata (for embedded checkout flow)
      def create_golfer_from_session(session)
        metadata = session.metadata
        return nil unless metadata.tournament_id.present? && metadata.golfer_email.present?

        tournament = Tournament.find_by(id: metadata.tournament_id)
        return nil unless tournament

        # Check if golfer already exists (race condition protection)
        existing = tournament.golfers.find_by(email: metadata.golfer_email)
        return existing if existing

        # Create the golfer
        golfer = tournament.golfers.create!(
          name: metadata.golfer_name,
          email: metadata.golfer_email,
          phone: metadata.golfer_phone,
          mobile: metadata.golfer_mobile.presence,
          company: metadata.golfer_company.presence,
          address: metadata.golfer_address.presence,
          payment_type: "stripe",
          payment_status: "unpaid", # Will be updated to paid right after
          waiver_accepted_at: Time.current,
          stripe_checkout_session_id: session.id
        )

        Rails.logger.info("Created golfer #{golfer.id} from embedded checkout session #{session.id}")
        golfer
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Failed to create golfer from session: #{e.message}")
        nil
      end

      # Handle embedded checkout in test mode
      def handle_test_mode_embedded(golfer_data, tournament)
        test_session_id = "test_embedded_#{SecureRandom.hex(16)}"
        
        # Store the golfer data temporarily (we'll create on confirm)
        Rails.cache.write(
          "test_embedded_#{test_session_id}",
          {
            tournament_id: tournament.id,
            golfer_data: golfer_data.to_unsafe_h,
          },
          expires_in: 1.hour
        )

        render json: {
          client_secret: "test_secret_#{test_session_id}",
          session_id: test_session_id,
          test_mode: true,
        }
      end

      # Handle checkout in test mode (no real Stripe calls)
      def handle_test_mode_checkout(golfer, setting)
        # Generate a fake session ID
        test_session_id = "test_session_#{SecureRandom.hex(16)}"
        
        # Save it to the golfer
        golfer.update!(stripe_checkout_session_id: test_session_id)

        # Get frontend URL for redirect
        frontend_url = ENV.fetch("FRONTEND_URL", "http://localhost:5173")

        render json: {
          # In test mode, we redirect directly to success page (simulating successful payment)
          checkout_url: "#{frontend_url}/payment/success?session_id=#{test_session_id}",
          session_id: test_session_id,
          golfer_id: golfer.id,
          test_mode: true,
        }
      end

      # Handle payment confirmation in test mode
      def handle_test_mode_confirm(session_id)
        golfer = Golfer.find_by(stripe_checkout_session_id: session_id)

        # For embedded test mode, create golfer from cached data
        if golfer.nil? && session_id.start_with?("test_embedded_")
          cached_data = Rails.cache.read("test_embedded_#{session_id}")
          if cached_data
            tournament = Tournament.find_by(id: cached_data[:tournament_id])
            if tournament
              golfer_data = cached_data[:golfer_data]
              golfer = tournament.golfers.create!(
                name: golfer_data["name"],
                email: golfer_data["email"],
                phone: golfer_data["phone"],
                mobile: golfer_data["mobile"].presence,
                company: golfer_data["company"].presence,
                address: golfer_data["address"].presence,
                payment_type: "stripe",
                payment_status: "unpaid",
                waiver_accepted_at: Time.current,
                stripe_checkout_session_id: session_id
              )
              Rails.cache.delete("test_embedded_#{session_id}")
            end
          end
        end

        unless golfer
          render json: { error: "Golfer not found for this test session" }, status: :not_found
          return
        end

        # Skip if already paid
        if golfer.payment_status == "paid"
          render json: {
            success: true,
            golfer: GolferSerializer.new(golfer),
            message: "Payment already confirmed (test mode)"
          }
          return
        end

        # Mark as paid (simulated)
        golfer.update!(
          payment_status: "paid",
          stripe_payment_intent_id: "test_pi_#{SecureRandom.hex(8)}",
          payment_method: "stripe",
          payment_notes: "SIMULATED PAYMENT (Test Mode) - #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
        )

        # Send registration confirmation email (since it was delayed for Stripe payments)
        GolferMailer.confirmation_email(golfer).deliver_later
        
        # Send payment confirmation email
        GolferMailer.payment_confirmation_email(golfer).deliver_later

        # Notify admin of new registration AND payment
        AdminMailer.notify_new_golfer(golfer).deliver_later
        AdminMailer.notify_payment_received(golfer).deliver_later

        # Broadcast update
        ActionCable.server.broadcast("golfers_channel", {
          action: "payment_confirmed",
          golfer: GolferSerializer.new(golfer).as_json
        })

        render json: {
          success: true,
          golfer: GolferSerializer.new(golfer),
          message: "Payment confirmed (test mode - no actual charge)",
          test_mode: true
        }
      end
    end
  end
end
