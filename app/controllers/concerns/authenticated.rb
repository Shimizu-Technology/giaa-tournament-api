module Authenticated
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_admin!
  end

  private

  def authenticate_admin!
    header = request.headers["Authorization"]

    unless header.present?
      render_unauthorized("Missing authorization header")
      return
    end

    token = header.split(" ").last
    decoded = ClerkAuth.verify(token)

    unless decoded
      render_unauthorized("Invalid or expired token")
      return
    end

    # Extract Clerk user ID from the token
    clerk_id = decoded["sub"]

    unless clerk_id
      render_unauthorized("Invalid token payload")
      return
    end

    # Find or create admin from Clerk ID
    @current_admin = Admin.find_or_create_by!(clerk_id: clerk_id) do |admin|
      admin.email = decoded["email"] || decoded["primary_email_address"]
      admin.name = decoded["name"] || decoded["first_name"]
      admin.role = Admin.count.zero? ? "super_admin" : "admin"
    end
  rescue ActiveRecord::RecordInvalid => e
    render_unauthorized("Failed to authenticate: #{e.message}")
  end

  def current_admin
    @current_admin
  end

  def render_unauthorized(message = "Unauthorized")
    render json: { error: message }, status: :unauthorized
  end

  def require_super_admin!
    unless current_admin&.super_admin?
      render json: { error: "Forbidden: Super admin access required" }, status: :forbidden
    end
  end
end

