class Golfer < ApplicationRecord
  belongs_to :tournament
  belongs_to :group, optional: true

  # Validations
  validates :name, presence: true
  validates :email, presence: true, 
                    uniqueness: { scope: :tournament_id, message: "has already registered for this tournament" },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, presence: true
  validates :payment_type, presence: true, inclusion: { in: %w[stripe pay_on_day] }
  validates :payment_status, inclusion: { in: %w[paid unpaid], allow_nil: true }
  validates :registration_status, inclusion: { in: %w[confirmed waitlist], allow_nil: true }
  validates :waiver_accepted_at, presence: true
  validates :tournament_id, presence: true

  # Scopes
  scope :confirmed, -> { where(registration_status: "confirmed") }
  scope :waitlist, -> { where(registration_status: "waitlist") }
  scope :paid, -> { where(payment_status: "paid") }
  scope :unpaid, -> { where(payment_status: "unpaid") }
  scope :checked_in, -> { where.not(checked_in_at: nil) }
  scope :not_checked_in, -> { where(checked_in_at: nil) }
  scope :unassigned, -> { where(group_id: nil) }
  scope :assigned, -> { where.not(group_id: nil) }
  scope :pay_now, -> { where(payment_type: "stripe") }
  scope :pay_on_day, -> { where(payment_type: "pay_on_day") }
  scope :for_tournament, ->(tournament_id) { where(tournament_id: tournament_id) }

  # Set registration status based on capacity
  before_validation :set_registration_status, on: :create
  before_validation :set_default_payment_status, on: :create

  # Callbacks - use after_commit to ensure golfer is persisted before jobs run
  after_commit :send_confirmation_email, on: :create
  after_commit :notify_admin, on: :create

  def checked_in?
    checked_in_at.present?
  end

  def check_in!
    # Toggle check-in status
    if checked_in?
      update!(checked_in_at: nil)
    else
      update!(checked_in_at: Time.current)
    end
  end

  def group_position_label
    return nil unless group && position
    letter = ("a".."d").to_a[position.to_i - 1] || "x"
    "#{group.group_number}#{letter.upcase}"
  end

  private

  def set_registration_status
    return if registration_status.present?
    return unless tournament

    if tournament.at_capacity?
      self.registration_status = "waitlist"
    else
      self.registration_status = "confirmed"
    end
  end

  def set_default_payment_status
    return if payment_status.present?
    
    # All new registrations start as unpaid
    # Stripe payments will be marked as paid after successful checkout
    # Pay on day payments will be marked as paid at check-in
    self.payment_status = "unpaid"
  end

  def send_confirmation_email
    return if Rails.env.test?
    GolferMailer.confirmation_email(self).deliver_later
  rescue StandardError => e
    Rails.logger.error("Failed to send golfer confirmation email: #{e.message}")
  end

  def notify_admin
    return if Rails.env.test?
    AdminMailer.notify_new_golfer(self).deliver_later
  rescue StandardError => e
    Rails.logger.error("Failed to send admin notification email: #{e.message}")
  end
end
