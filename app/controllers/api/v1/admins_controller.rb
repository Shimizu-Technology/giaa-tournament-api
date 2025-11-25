module Api
  module V1
    class AdminsController < BaseController
      before_action :require_super_admin!, except: [:me]

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
      # Create a new admin (invite)
      def create
        admin = Admin.new(admin_params)
        admin.role = "admin" # Only super_admin can create admins, but they start as regular admin

        if admin.save
          render json: admin, status: :created
        else
          render json: { errors: admin.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/admins/:id
      def update
        admin = Admin.find(params[:id])

        # Prevent demoting the last super admin
        if admin.super_admin? && params[:role] == "admin"
          if Admin.super_admins.count <= 1
            render json: { error: "Cannot demote the last super admin" }, status: :unprocessable_entity
            return
          end
        end

        if admin.update(admin_params)
          render json: admin
        else
          render json: { errors: admin.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/admins/:id
      def destroy
        admin = Admin.find(params[:id])

        # Prevent deleting the last super admin
        if admin.super_admin? && Admin.super_admins.count <= 1
          render json: { error: "Cannot delete the last super admin" }, status: :unprocessable_entity
          return
        end

        # Prevent self-deletion
        if admin.id == current_admin.id
          render json: { error: "Cannot delete yourself" }, status: :unprocessable_entity
          return
        end

        admin.destroy
        head :no_content
      end

      private

      def admin_params
        params.require(:admin).permit(:clerk_id, :name, :email, :role)
      end
    end
  end
end

