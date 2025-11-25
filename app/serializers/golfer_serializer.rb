class GolferSerializer < ActiveModel::Serializer
  attributes :id, :name, :company, :address, :phone, :mobile, :email,
             :payment_type, :payment_status, :waiver_accepted_at,
             :checked_in_at, :registration_status, :group_id, :hole_number,
             :position, :notes, :payment_method, :receipt_number, :payment_notes,
             :created_at, :updated_at, :group_position_label, :checked_in

  belongs_to :group, optional: true

  def checked_in
    object.checked_in?
  end

  def group_position_label
    object.group_position_label
  end
end

