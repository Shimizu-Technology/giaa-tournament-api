module Api
  module V1
    class SettingsController < BaseController
      # GET /api/v1/settings
      def show
        setting = Setting.instance
        render json: setting
      end

      # PATCH /api/v1/settings
      def update
        setting = Setting.instance

        if setting.update(setting_params)
          render json: setting
        else
          render json: { errors: setting.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def setting_params
        params.require(:setting).permit(
          :max_capacity,
          :stripe_public_key,
          :stripe_secret_key,
          :stripe_webhook_secret,
          :tournament_entry_fee,
          :payment_mode,
          :admin_email,
          :registration_open,
          # Tournament configuration
          :tournament_year,
          :tournament_edition,
          :tournament_title,
          :tournament_name,
          :event_date,
          :registration_time,
          :start_time,
          :location_name,
          :location_address,
          :format_name,
          :fee_includes,
          :checks_payable_to,
          :contact_name,
          :contact_phone
        )
      end
    end
  end
end

