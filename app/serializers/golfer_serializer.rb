class GolferSerializer < ActiveModel::Serializer
  attributes :id, :tournament_id, :name, :company, :address, :phone, :mobile, :email,
             :payment_type, :payment_status, :waiver_accepted_at,
             :checked_in_at, :registration_status, :group_id, :hole_number,
             :position, :notes, :payment_method, :receipt_number, :payment_notes,
             :created_at, :updated_at, :group_position_label, :checked_in, :waiver_signed,
             # Employee fields
             :is_employee, :employee_number,
             # Payment link
             :payment_token,
             # Refund/payment detail fields
             :stripe_card_brand, :stripe_card_last4, :payment_amount_cents,
             :stripe_refund_id, :refund_amount_cents, :refund_reason, :refunded_at,
             :refunded_by_name, :can_refund, :can_cancel, :cancelled, :refunded,
             :formatted_payment_timestamp

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

  def refunded_by_name
    object.refunded_by&.name || object.refunded_by&.email
  end

  def can_refund
    object.can_refund?
  end

  def can_cancel
    object.can_cancel?
  end

  def cancelled
    object.cancelled?
  end

  def refunded
    object.refunded?
  end

  # Format the payment timestamp nicely
  def formatted_payment_timestamp
    return nil unless object.payment_notes.present?
    
    # Try to extract and format the timestamp from payment_notes
    # If the payment was made via Stripe, format the timestamp from when it was recorded
    if object.payment_status == "paid" && object.payment_type == "stripe"
      # Find the timestamp in the payment notes
      if match = object.payment_notes&.match(/(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})/)
        begin
          time = Time.parse(match[1])
          return time.in_time_zone('Pacific/Guam').strftime('%B %d, %Y at %I:%M %p')
        rescue
          nil
        end
      end
    end
    nil
  end
end
