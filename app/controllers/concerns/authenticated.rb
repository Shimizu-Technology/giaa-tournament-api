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

    # Extract Clerk user ID and email from the token
    clerk_id = decoded["sub"]
    email = decoded["email"] || decoded["primary_email_address"]

    # Debug logging
    Rails.logger.info "=== Admin Auth Debug ==="
    Rails.logger.info "Clerk ID: #{clerk_id}"
    Rails.logger.info "Email from token: #{email.inspect}"
    Rails.logger.info "All decoded fields: #{decoded.keys.join(', ')}"
    
    unless clerk_id
      render_unauthorized("Invalid token payload")
      return
    end

    # Find admin by clerk_id or email (whitelist check)
    @current_admin = Admin.find_by_clerk_or_email(clerk_id: clerk_id, email: email)
    Rails.logger.info "Found admin: #{@current_admin.inspect}"

    unless @current_admin
      render_unauthorized("Access denied. You are not authorized as an admin. Please contact an existing admin to be added.")
      return
    end

    # If admin was found by email but doesn't have clerk_id yet, link the account
    if @current_admin.clerk_id.nil?
      @current_admin.update!(
        clerk_id: clerk_id,
        name: @current_admin.name || decoded["name"] || decoded["first_name"]
      )
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

