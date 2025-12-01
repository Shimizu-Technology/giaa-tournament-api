class EmployeeNumber < ApplicationRecord
  belongs_to :tournament
  belongs_to :used_by_golfer, class_name: 'Golfer', optional: true

  validates :employee_number, presence: true
  validates :employee_number, uniqueness: { scope: :tournament_id, message: "already exists for this tournament" }

  scope :available, -> { where(used: false) }
  scope :used_numbers, -> { where(used: true) }

  # Mark this employee number as used by a golfer
  def mark_used!(golfer)
    update!(used: true, used_by_golfer: golfer)
  end

  # Release this employee number (e.g., if registration is cancelled)
  def release!
    update!(used: false, used_by_golfer: nil)
  end

  # Check if this employee number is available
  def available?
    !used?
  end

  # Display format for admin
  def display_name
    if employee_name.present?
      "#{employee_number} (#{employee_name})"
    else
      employee_number
    end
  end

  # Status for display
  def status
    if used?
      "Used by #{used_by_golfer&.name || 'Unknown'}"
    else
      "Available"
    end
  end
end

