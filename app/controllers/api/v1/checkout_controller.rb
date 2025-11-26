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
                  name: "GIAA Golf Tournament Entry Fee",
                  description: "Edward A.P. Muna II Memorial Golf Tournament - #{golfer.name}",
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

      # POST /api/v1/checkout/confirm
      # Called after successful payment - verifies with Stripe and updates golfer
      def confirm
        session_id = params[:session_id]

        unless session_id.present?
          render json: { error: "Session ID is required" }, status: :bad_request
          return
        end

        setting = Setting.instance

        # Handle test mode confirmation
        if session_id.start_with?("test_session_")
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

          # Find the golfer by session ID
          golfer = Golfer.find_by(stripe_checkout_session_id: session_id)

          unless golfer
            # Try to find by metadata golfer_id
            golfer_id = session.metadata.golfer_id
            golfer = Golfer.find(golfer_id) if golfer_id.present?
          end

          unless golfer
            render json: { error: "Golfer not found for this session" }, status: :not_found
            return
          end

          # Check if payment was successful
          if session.payment_status == "paid"
            # Get the payment intent ID for record keeping
            payment_intent_id = session.payment_intent

            # Update golfer payment status
            golfer.update!(
              payment_status: "paid",
              stripe_payment_intent_id: payment_intent_id,
              payment_method: "stripe",
              payment_notes: "Paid via Stripe on #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"
            )

            # Send confirmation email
            GolferMailer.payment_confirmation_email(golfer).deliver_later

            # Notify admin
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
          else
            render json: {
              success: false,
              payment_status: session.payment_status,
              message: "Payment has not been completed yet"
            }, status: :payment_required
          end
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

        # Send confirmation email (even in test mode, for testing email flow)
        GolferMailer.payment_confirmation_email(golfer).deliver_later

        # Notify admin
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
