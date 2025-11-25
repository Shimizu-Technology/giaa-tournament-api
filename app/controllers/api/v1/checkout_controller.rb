module Api
  module V1
    class CheckoutController < BaseController
      skip_before_action :authenticate_admin!

      # POST /api/v1/checkout
      # Create a Stripe checkout session
      def create
        golfer = Golfer.find(params[:golfer_id])

        # Ensure golfer hasn't already paid
        if golfer.payment_status == "paid"
          render json: { error: "Golfer has already paid" }, status: :unprocessable_entity
          return
        end

        setting = Setting.instance

        unless setting.stripe_secret_key.present?
          render json: { error: "Stripe is not configured" }, status: :service_unavailable
          return
        end

        # In production, you would use Stripe SDK here
        # For now, we return a placeholder since Clerk handles the actual Stripe integration
        # The frontend will use Clerk's payment components

        render json: {
          message: "Checkout session created",
          golfer_id: golfer.id,
          amount: 15000, # $150.00 in cents (example tournament fee)
          currency: "usd"
        }
      end

      # POST /api/v1/checkout/confirm
      # Called after successful payment (webhook or frontend callback)
      def confirm
        golfer = Golfer.find(params[:golfer_id])

        golfer.update!(payment_status: "paid")

        # Send confirmation email
        GolferMailer.payment_confirmation_email(golfer).deliver_later

        # Broadcast update
        ActionCable.server.broadcast("golfers_channel", {
          action: "payment_confirmed",
          golfer: GolferSerializer.new(golfer).as_json
        })

        render json: golfer
      rescue StandardError => e
        Rails.logger.error("Payment confirmation failed: #{e.message}")
        render json: { error: "Payment confirmation failed" }, status: :unprocessable_entity
      end
    end
  end
end

