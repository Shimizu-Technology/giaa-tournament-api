class GolferMailer < ApplicationMailer
  helper PhoneHelper

  # Send confirmation email to golfer after registration (for Pay Later)
  def confirmation_email(golfer)
    @golfer = golfer
    @status = golfer.registration_status
    @is_confirmed = @status == "confirmed"
    @setting = Setting.instance
    @tournament = golfer.tournament
    @is_employee = golfer.is_employee
    @entry_fee = calculate_entry_fee(golfer)

    subject = @is_confirmed ?
      "Your Golf Tournament Registration is Confirmed!" :
      "You've Been Added to the Waitlist"

    mail(to: golfer.email, subject: subject)
  end

  # Send payment confirmation after successful payment (for manual payments - legacy)
  def payment_confirmation_email(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @is_employee = golfer.is_employee
    @entry_fee = calculate_entry_fee(golfer)

    mail(
      to: golfer.email,
      subject: "Payment Received - Golf Tournament Registration"
    )
  end

  # Combined confirmation + payment email for Stripe payments
  def confirmation_with_payment_email(golfer)
    @golfer = golfer
    @status = golfer.registration_status
    @is_confirmed = @status == "confirmed"
    @setting = Setting.instance
    @tournament = golfer.tournament
    @is_employee = golfer.is_employee
    # For Stripe payments, use the actual amount paid
    @entry_fee = (golfer.payment_amount_cents || calculate_entry_fee_cents(golfer)).to_f / 100

    subject = @is_confirmed ?
      "Registration Confirmed & Payment Received!" :
      "Waitlist Confirmed & Payment Received!"

    mail(to: golfer.email, subject: subject)
  end

  # Send email when promoted from waitlist to confirmed
  def promotion_email(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @is_employee = golfer.is_employee
    @entry_fee = calculate_entry_fee(golfer)

    mail(
      to: golfer.email,
      subject: "Great News! Your Golf Tournament Spot is Confirmed!"
    )
  end

  # Send refund confirmation email
  def refund_confirmation_email(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @refund_amount = golfer.refund_amount_cents.to_f / 100

    mail(
      to: golfer.email,
      subject: "Refund Processed - Golf Tournament Registration"
    )
  end

  # Send cancellation confirmation email (for non-refund cancellations)
  def cancellation_email(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament

    mail(
      to: golfer.email,
      subject: "Registration Cancelled - Golf Tournament"
    )
  end

  # Send payment link email
  def payment_link_email(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @is_employee = golfer.is_employee
    @entry_fee = calculate_entry_fee(golfer)
    @payment_link = golfer.payment_link_url

    mail(
      to: golfer.email,
      subject: "Complete Your Payment - #{@tournament&.name || 'Golf Tournament'}"
    )
  end

  private

  # Calculate entry fee based on employee status
  def calculate_entry_fee(golfer)
    calculate_entry_fee_cents(golfer).to_f / 100
  end

  def calculate_entry_fee_cents(golfer)
    tournament = golfer.tournament
    if golfer.is_employee
      tournament&.employee_entry_fee || 5000
    else
      tournament&.entry_fee || 12500
    end
  end
end
