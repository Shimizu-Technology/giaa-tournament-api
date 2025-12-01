class AdminMailer < ApplicationMailer
  helper PhoneHelper

  # Notify admin of new golfer registration (for Pay Later registrations)
  def notify_new_golfer(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @is_employee = golfer.is_employee
    @entry_fee = calculate_entry_fee(golfer)
    admin_email = @setting.admin_email

    return unless admin_email.present?

    subject = @is_employee ? 
      "New Employee Registration: #{golfer.name}" :
      "New Golf Tournament Registration: #{golfer.name}"

    mail(to: admin_email, subject: subject)
  end

  # Notify admin of payment received (for manual payments marked by admin - rarely used)
  def notify_payment_received(golfer)
    @golfer = golfer
    @setting = Setting.instance
    @tournament = golfer.tournament
    @is_employee = golfer.is_employee
    @entry_fee = calculate_entry_fee(golfer)
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
    @is_employee = golfer.is_employee
    @entry_fee = (@golfer.payment_amount_cents || calculate_entry_fee_cents(golfer)).to_f / 100
    admin_email = @setting.admin_email

    return unless admin_email.present?

    subject = @is_employee ?
      "New Employee Registration & Payment: #{golfer.name}" :
      "New Registration & Payment: #{golfer.name}"

    mail(to: admin_email, subject: subject)
  end

  private

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

