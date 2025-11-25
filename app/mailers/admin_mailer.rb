class AdminMailer < ApplicationMailer
  # Notify admin of new golfer registration
  def notify_new_golfer(golfer)
    @golfer = golfer
    admin_email = Setting.first&.admin_email

    return unless admin_email.present?

    mail(
      to: admin_email,
      subject: "New Golf Tournament Registration: #{golfer.name}"
    )
  end

  # Notify admin of payment received
  def notify_payment_received(golfer)
    @golfer = golfer
    admin_email = Setting.first&.admin_email

    return unless admin_email.present?

    mail(
      to: admin_email,
      subject: "Payment Received: #{golfer.name}"
    )
  end
end

