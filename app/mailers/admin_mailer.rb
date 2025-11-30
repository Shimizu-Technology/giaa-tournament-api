class AdminMailer < ApplicationMailer
  helper PhoneHelper

  # Notify admin of new golfer registration (for Pay Later registrations)
  def notify_new_golfer(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @entry_fee = (@tournament&.entry_fee || 12500).to_f / 100
    admin_email = @setting.admin_email

    return unless admin_email.present?

    mail(
      to: admin_email,
      subject: "New Golf Tournament Registration: #{golfer.name}"
    )
  end

  # Notify admin of payment received (for manual payments marked by admin - rarely used)
  def notify_payment_received(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @entry_fee = (@tournament&.entry_fee || 12500).to_f / 100
    admin_email = @setting.admin_email

    return unless admin_email.present?

    mail(
      to: admin_email,
      subject: "Payment Received: #{golfer.name}"
    )
  end

  # Combined notification for Stripe payments (registration + payment in one email)
  def notify_new_registration_with_payment(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @entry_fee = (@golfer.payment_amount_cents || @tournament&.entry_fee || 12500).to_f / 100
    admin_email = @setting.admin_email

    return unless admin_email.present?

    mail(
      to: admin_email,
      subject: "New Registration & Payment: #{golfer.name}"
    )
  end
end

