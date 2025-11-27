module Api
  module V1
    class AdminsController < BaseController
      # All admins can manage other admins (no super_admin restriction)

      # GET /api/v1/admins
      def index
        admins = Admin.all.order(:created_at)
        render json: admins
      end

      # GET /api/v1/admins/me
      def me
        render json: current_admin
      end

      # GET /api/v1/admins/:id
      def show
        admin = Admin.find(params[:id])
        render json: admin
      end

      # POST /api/v1/admins
      # Add a new admin by email (they'll be linked when they first log in)
      def create
        email = params.dig(:admin, :email)&.downcase&.strip

        if email.blank?
          render json: { errors: ["Email is required"] }, status: :unprocessable_entity
          return
        end

        # Check if admin already exists
        if Admin.exists?(["LOWER(email) = ?", email])
          render json: { errors: ["An admin with this email already exists"] }, status: :unprocessable_entity
          return
        end

        admin = Admin.new(
          email: email,
          name: params.dig(:admin, :name),
          role: "admin"
        )

        if admin.save
          ActivityLog.log(
            admin: current_admin,
            action: 'admin_created',
            target: admin,
            details: "Added new admin: #{admin.email}"
          )
          render json: admin, status: :created
        else
          render json: { errors: admin.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/admins/:id
      def update
        admin = Admin.find(params[:id])

        if admin.update(admin_update_params)
          render json: admin
        else
          render json: { errors: admin.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/admins/:id
      def destroy
        admin = Admin.find(params[:id])

        # Prevent deleting the last admin
        if Admin.count <= 1
          render json: { error: "Cannot delete the last admin" }, status: :unprocessable_entity
          return
        end

        # Prevent self-deletion
        if admin.id == current_admin.id
          render json: { error: "Cannot delete yourself" }, status: :unprocessable_entity
          return
        end

        admin_email = admin.email
        admin.destroy
        
        ActivityLog.log(
          admin: current_admin,
          action: 'admin_deleted',
          target: nil,
          details: "Removed admin: #{admin_email}",
          metadata: { deleted_email: admin_email }
        )
        
        head :no_content
      end

      private

      def admin_update_params
        params.require(:admin).permit(:name, :email)
      end
    end
  end
end

