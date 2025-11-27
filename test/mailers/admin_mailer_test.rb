require "test_helper"

class AdminMailerTest < ActionMailer::TestCase
  def setup
    @golfer = golfers(:confirmed_paid)
    @setting = Setting.instance
    @setting.update!(admin_email: "admin-test@example.com")
  end

  test "notify_new_golfer" do
    mail = AdminMailer.notify_new_golfer(@golfer)
    
    assert_equal "New Golf Tournament Registration: #{@golfer.name}", mail.subject
    assert_equal ["admin-test@example.com"], mail.to
    assert_match @golfer.name, mail.body.encoded
    assert_match @golfer.email, mail.body.encoded
  end

  test "notify_new_golfer returns nil without admin_email" do
    @setting.update!(admin_email: nil)
    mail = AdminMailer.notify_new_golfer(@golfer)
    
    # Should return nil/no mail when admin_email is not set
    assert_nil mail.to
  end

  test "notify_payment_received" do
    mail = AdminMailer.notify_payment_received(@golfer)
    
    assert_equal "Payment Received: #{@golfer.name}", mail.subject
    assert_equal ["admin-test@example.com"], mail.to
  end
end
