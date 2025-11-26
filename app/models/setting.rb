class Setting < ApplicationRecord
  PAYMENT_MODES = %w[test production].freeze

  validates :max_capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :tournament_entry_fee, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :payment_mode, inclusion: { in: PAYMENT_MODES }, allow_nil: true

  # Singleton pattern - only one settings record
  def self.instance
    first_or_create!(
      max_capacity: 160,
      admin_email: nil,
      stripe_public_key: nil,
      stripe_secret_key: nil,
      stripe_webhook_secret: nil,
      tournament_entry_fee: 12500, # $125.00 in cents
      payment_mode: 'test'
    )
  end

  def stripe_configured?
    stripe_public_key.present? && stripe_secret_key.present?
  end

  def test_mode?
    payment_mode == 'test' || payment_mode.nil?
  end

  def production_mode?
    payment_mode == 'production'
  end

  def entry_fee_dollars
    return 125.00 if tournament_entry_fee.nil?
    tournament_entry_fee / 100.0
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
