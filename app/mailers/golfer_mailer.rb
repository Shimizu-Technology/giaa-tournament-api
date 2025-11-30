class GolferMailer < ApplicationMailer
  helper PhoneHelper

  # Send confirmation email to golfer after registration
  def confirmation_email(golfer)
    @golfer = golfer
    @status = golfer.registration_status
    @is_confirmed = @status == "confirmed"
    @setting = Setting.instance
    @tournament = golfer.tournament
    @entry_fee = @tournament&.entry_fee.to_f / 100

    subject = @is_confirmed ?
      "Your Golf Tournament Registration is Confirmed!" :
      "You've Been Added to the Waitlist"

    mail(to: golfer.email, subject: subject)
  end

  # Send payment confirmation after successful payment
  def payment_confirmation_email(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @entry_fee = @tournament&.entry_fee.to_f / 100

    mail(
      to: golfer.email,
      subject: "Payment Received - Golf Tournament Registration"
    )
  end

  # Send email when promoted from waitlist to confirmed
  def promotion_email(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @entry_fee = @tournament&.entry_fee.to_f / 100

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
end
