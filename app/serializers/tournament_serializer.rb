class TournamentSerializer < ActiveModel::Serializer
  attributes :id, :name, :year, :edition, :status,
             :event_date, :registration_time, :start_time,
             :location_name, :location_address,
             :max_capacity, :entry_fee, :entry_fee_dollars,
             :format_name, :fee_includes, :checks_payable_to,
             :contact_name, :contact_phone,
             :registration_open, :can_register,
             :confirmed_count, :waitlist_count, :capacity_remaining, :at_capacity,
             :checked_in_count, :paid_count,
             :display_name, :short_name,
             :created_at, :updated_at

  def entry_fee_dollars
    object.entry_fee_dollars
  end

  def can_register
    object.can_register?
  end

  def confirmed_count
    object.confirmed_count
  end

  def waitlist_count
    object.waitlist_count
  end

  def capacity_remaining
    object.capacity_remaining
  end

  def at_capacity
    object.at_capacity?
  end

  def checked_in_count
    object.checked_in_count
  end

  def paid_count
    object.paid_count
  end

  def display_name
    object.display_name
  end

  def short_name
    object.short_name
  end

  def created_at
    object.created_at.in_time_zone('Guam').iso8601
  end

  def updated_at
    object.updated_at.in_time_zone('Guam').iso8601
  end
end

