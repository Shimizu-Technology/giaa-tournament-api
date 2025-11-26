class AdminMailer < ApplicationMailer
  helper PhoneHelper

  # Notify admin of new golfer registration
  def notify_new_golfer(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @entry_fee = @setting.tournament_entry_fee.to_f / 100
    admin_email = @setting.admin_email

    return unless admin_email.present?

    mail(
      to: admin_email,
      subject: "New Golf Tournament Registration: #{golfer.name}"
    )
  end

  # Notify admin of payment received
  def notify_payment_received(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @entry_fee = @setting.tournament_entry_fee.to_f / 100
    admin_email = @setting.admin_email

    return unless admin_email.present?

    mail(
      to: admin_email,
      subject: "Payment Received: #{golfer.name}"
    )
  end
end

