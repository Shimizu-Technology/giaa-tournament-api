class GolferSerializer < ActiveModel::Serializer
  attributes :id, :tournament_id, :name, :company, :address, :phone, :mobile, :email,
             :payment_type, :payment_status, :waiver_accepted_at,
             :checked_in_at, :registration_status, :group_id, :hole_number,
             :position, :notes, :payment_method, :receipt_number, :payment_notes,
             :created_at, :updated_at, :group_position_label, :checked_in, :waiver_signed

  belongs_to :group, optional: true

  def checked_in
    object.checked_in?
  end

  def waiver_signed
    object.waiver_accepted_at.present?
  end

  def group_position_label
    object.group_position_label
  end

  # Get hole_number from the group, not from the golfer directly
  def hole_number
    object.group&.hole_number
  end
end

