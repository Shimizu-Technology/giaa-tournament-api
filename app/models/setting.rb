class Setting < ApplicationRecord
  validates :max_capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # Singleton pattern - only one settings record
  def self.instance
    first_or_create!(
      max_capacity: 160,
      admin_email: nil,
      stripe_public_key: nil,
      stripe_secret_key: nil
    )
  end

  def capacity_remaining
    return max_capacity if max_capacity.nil?
    remaining = max_capacity - Golfer.confirmed.count
    remaining.negative? ? 0 : remaining
  end

  def at_capacity?
    return false if max_capacity.nil?
    Golfer.confirmed.count >= max_capacity
  end
end
