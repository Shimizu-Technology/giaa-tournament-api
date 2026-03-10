class TournamentSerializer < ActiveModel::Serializer
  attributes :id, :name, :year, :edition, :status,
             :event_date, :registration_time, :start_time,
             :location_name, :location_address,
             :max_capacity, :reserved_slots,
             :entry_fee, :entry_fee_dollars,
             :employee_entry_fee, :employee_entry_fee_dollars,
             :employee_numbers_count,
             :format_name, :fee_includes, :checks_payable_to,
             :contact_name, :contact_phone,
             :registration_open, :can_register,
             :confirmed_count, :waitlist_count,
             :capacity_remaining, :at_capacity,
             :public_capacity, :public_capacity_remaining, :public_at_capacity,
             :checked_in_count, :paid_count,
             :display_name, :short_name,
             :created_at, :updated_at

  def entry_fee_dollars
    object.entry_fee_dollars
  end

  def employee_entry_fee_dollars
    object.employee_entry_fee_dollars
  end

  def employee_numbers_count
    object.employee_numbers.size
  end

  def can_register
    object.can_register?
  end

  # Use precomputed counts if available (set by controller), otherwise fall back to queries
  def confirmed_count
    precomputed_counts[:confirmed] || object.confirmed_count
  end

  def waitlist_count
    precomputed_counts[:waitlist] || object.waitlist_count
  end

  def capacity_remaining
    return object.max_capacity if object.max_capacity.nil?
    remaining = object.max_capacity - confirmed_count
    remaining.negative? ? 0 : remaining
  end

  def at_capacity
    return false if object.max_capacity.nil?
    confirmed_count >= object.max_capacity
  end

  def public_capacity
    return object.max_capacity if object.max_capacity.nil?
    public_cap = object.max_capacity - (object.reserved_slots || 0)
    public_cap.negative? ? 0 : public_cap
  end

  def public_capacity_remaining
    cap = public_capacity
    return cap if cap.nil?
    remaining = cap - confirmed_count
    remaining.negative? ? 0 : remaining
  end

  def public_at_capacity
    return false if object.max_capacity.nil?
    confirmed_count >= public_capacity
  end

  def checked_in_count
    precomputed_counts[:checked_in] || object.checked_in_count
  end

  def paid_count
    precomputed_counts[:paid] || object.paid_count
  end

  private

  def precomputed_counts
    @precomputed_counts ||= if object.instance_variable_defined?(:@precomputed_counts)
      object.instance_variable_get(:@precomputed_counts)
    else
      {}
    end
  end

  def display_name
    object.display_name
  end

  def short_name
    object.short_name
  end

  def created_at
    object.created_at.in_time_zone("Guam").iso8601
  end

  def updated_at
    object.updated_at.in_time_zone("Guam").iso8601
  end
end
