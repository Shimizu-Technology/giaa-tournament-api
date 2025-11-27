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

    # Extract name from Clerk token
    clerk_name = decoded["name"] || decoded["first_name"] || 
                 [decoded["first_name"], decoded["last_name"]].compact.join(' ').presence

    # Update admin record if needed
    updates = {}
    updates[:clerk_id] = clerk_id if @current_admin.clerk_id.nil?
    updates[:name] = clerk_name if @current_admin.name.blank? && clerk_name.present?
    
    if updates.any?
      @current_admin.update!(updates)
      Rails.logger.info "Updated admin: #{updates.inspect}"
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

