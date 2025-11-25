module Api
  module V1
    class SettingsController < BaseController
      before_action :require_super_admin!, except: [:show]

      # GET /api/v1/settings
      def show
        setting = Setting.instance

        # Don't expose secret key to non-super admins
        if current_admin.super_admin?
          render json: setting
        else
          render json: setting, except: [:stripe_secret_key]
        end
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
          :admin_email
        )
      end
    end
  end
end

