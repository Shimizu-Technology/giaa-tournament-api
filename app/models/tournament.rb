class Tournament < ApplicationRecord
  # Associations
  has_many :golfers, dependent: :restrict_with_error
  has_many :groups, dependent: :restrict_with_error
  has_many :activity_logs, dependent: :nullify
  has_many :employee_numbers, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :year, presence: true, numericality: { only_integer: true }
  validates :status, presence: true, inclusion: { in: %w[draft open closed archived] }
  validates :max_capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :entry_fee, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :employee_entry_fee, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  # Scopes
  scope :active, -> { where.not(status: 'archived') }
  scope :archived, -> { where(status: 'archived') }
  scope :open_for_registration, -> { where(status: 'open', registration_open: true) }
  scope :by_year, ->(year) { where(year: year) }
  scope :recent, -> { order(year: :desc, created_at: :desc) }

  # Status constants
  STATUSES = %w[draft open closed archived].freeze

  # Class methods
  def self.current
    # Returns the currently open tournament (for public registration)
    open_for_registration.first || active.recent.first
  end

  # Instance methods
  def draft?
    status == 'draft'
  end

  def open?
    status == 'open'
  end

  def closed?
    status == 'closed'
  end

  def archived?
    status == 'archived'
  end

  def can_register?
    open? && registration_open?
  end

  def entry_fee_dollars
    return 125.00 if entry_fee.nil?
    entry_fee / 100.0
  end

  def employee_entry_fee_dollars
    return 50.00 if employee_entry_fee.nil?
    employee_entry_fee / 100.0
  end

  # Check if an employee number is valid and available
  def validate_employee_number(number)
    return { valid: false, error: "Employee number is required" } if number.blank?
    
    emp_record = employee_numbers.find_by(employee_number: number)
    
    return { valid: false, error: "Invalid employee number" } unless emp_record
    return { valid: false, error: "This employee number has already been used" } if emp_record.used?
    
    { valid: true, employee_number_record: emp_record }
  end

  def confirmed_count
    golfers.confirmed.count
  end

  def waitlist_count
    golfers.waitlist.count
  end

  # Total capacity remaining (for admin view)
  def capacity_remaining
    return max_capacity if max_capacity.nil?
    remaining = max_capacity - confirmed_count
    remaining.negative? ? 0 : remaining
  end

  # Public-facing capacity (excludes reserved slots)
  def public_capacity
    return max_capacity if max_capacity.nil?
    public_cap = max_capacity - (reserved_slots || 0)
    public_cap.negative? ? 0 : public_cap
  end

  # Spots remaining for public registration
  def public_capacity_remaining
    return public_capacity if public_capacity.nil?
    remaining = public_capacity - confirmed_count
    remaining.negative? ? 0 : remaining
  end

  # Is public registration at capacity?
  def public_at_capacity?
    return false if max_capacity.nil?
    confirmed_count >= public_capacity
  end

  # Is total capacity reached (including reserved)?
  def at_capacity?
    return false if max_capacity.nil?
    confirmed_count >= max_capacity
  end

  def checked_in_count
    golfers.checked_in.count
  end

  def paid_count
    golfers.paid.count
  end

  def display_name
    "#{edition} #{name} (#{year})"
  end

  def short_name
    "#{year} Tournament"
  end

  # Archive this tournament
  def archive!
    update!(status: 'archived', registration_open: false)
  end

  # Copy this tournament to create a new one for next year
  def copy_for_next_year
    Tournament.new(
      name: name,
      year: year + 1,
      edition: increment_edition,
      status: 'draft',
      event_date: nil, # User should set new date
      registration_time: registration_time,
      start_time: start_time,
      location_name: location_name,
      location_address: location_address,
      max_capacity: max_capacity,
      reserved_slots: reserved_slots,
      entry_fee: entry_fee,
      employee_entry_fee: employee_entry_fee,
      format_name: format_name,
      fee_includes: fee_includes,
      checks_payable_to: checks_payable_to,
      contact_name: contact_name,
      contact_phone: contact_phone,
      registration_open: false
    )
  end

  private

  def increment_edition
    return '1st' if edition.blank?
    
    # Extract number from edition (e.g., "5th" -> 5)
    current_num = edition.to_i
    next_num = current_num + 1
    
    case next_num
    when 1 then '1st'
    when 2 then '2nd'
    when 3 then '3rd'
    else "#{next_num}th"
    end
  end
end
