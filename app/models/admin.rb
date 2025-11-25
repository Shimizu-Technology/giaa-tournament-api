class Admin < ApplicationRecord
  validates :clerk_id, presence: true, uniqueness: true
  validates :role, inclusion: { in: %w[super_admin admin] }, allow_nil: true

  # Scopes
  scope :super_admins, -> { where(role: "super_admin") }
  scope :regular_admins, -> { where(role: "admin") }

  def super_admin?
    role == "super_admin"
  end

  def admin?
    role == "admin" || super_admin?
  end
end
