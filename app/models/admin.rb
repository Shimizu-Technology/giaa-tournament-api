class Admin < ApplicationRecord
  has_many :activity_logs, dependent: :nullify

  # clerk_id is optional until the admin first logs in
  validates :clerk_id, uniqueness: true, allow_nil: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :role, inclusion: { in: %w[super_admin admin] }, allow_nil: true

  # Normalize email before validation
  before_validation :normalize_email

  # Scopes
  scope :super_admins, -> { where(role: "super_admin") }
  scope :regular_admins, -> { where(role: "admin") }

  # Find admin by clerk_id or email
  def self.find_by_clerk_or_email(clerk_id:, email:)
    # First try to find by clerk_id
    admin = find_by(clerk_id: clerk_id) if clerk_id.present?
    return admin if admin

    # Then try by email
    find_by("LOWER(email) = ?", email&.downcase) if email.present?
  end

  def super_admin?
    role == "super_admin"
  end

  def admin?
    role == "admin" || super_admin?
  end

  private

  def normalize_email
    self.email = email&.downcase&.strip
  end
end
