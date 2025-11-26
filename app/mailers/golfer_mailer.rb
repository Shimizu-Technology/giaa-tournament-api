class GolferMailer < ApplicationMailer
  helper PhoneHelper

  # Send confirmation email to golfer after registration
  def confirmation_email(golfer)
    @golfer = golfer
    @status = golfer.registration_status
    @is_confirmed = @status == "confirmed"
    @setting = Setting.instance
    @entry_fee = @setting.tournament_entry_fee.to_f / 100

    subject = @is_confirmed ?
      "Your Golf Tournament Registration is Confirmed!" :
      "You've Been Added to the Waitlist"

    mail(to: golfer.email, subject: subject)
  end

  # Send payment confirmation after successful payment
  def payment_confirmation_email(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @entry_fee = @setting.tournament_entry_fee.to_f / 100

    mail(
      to: golfer.email,
      subject: "Payment Received - Golf Tournament Registration"
    )
  end

  # Send email when promoted from waitlist to confirmed
  def promotion_email(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @entry_fee = @setting.tournament_entry_fee.to_f / 100

    mail(
      to: golfer.email,
      subject: "Great News! Your Golf Tournament Spot is Confirmed!"
    )
  end
end

