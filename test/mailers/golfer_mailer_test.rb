require "test_helper"

class GolferMailerTest < ActionMailer::TestCase
  def setup
    @golfer = golfers(:confirmed_paid)
    @waitlist_golfer = golfers(:waitlist_golfer)
    @setting = Setting.instance
    @setting.update!(
      tournament_name: "Test Tournament",
      event_date: "January 1, 2026",
      location_name: "Test Golf Course",
      registration_time: "11:00 am",
      start_time: "12:30 pm",
      contact_name: "Test Contact",
      contact_phone: "671-555-0000",
      tournament_entry_fee: 12500
    )
  end

  test "confirmation_email for confirmed golfer" do
    mail = GolferMailer.confirmation_email(@golfer)
    
    assert_equal "Your Golf Tournament Registration is Confirmed!", mail.subject
    assert_equal [@golfer.email], mail.to
    assert_match @golfer.name, mail.body.encoded
  end

  test "confirmation_email for waitlist golfer" do
    mail = GolferMailer.confirmation_email(@waitlist_golfer)
    
    assert_equal "You've Been Added to the Waitlist", mail.subject
    assert_equal [@waitlist_golfer.email], mail.to
  end

  test "promotion_email for waitlist to confirmed" do
    mail = GolferMailer.promotion_email(@waitlist_golfer)
    
    assert_equal "Great News! Your Golf Tournament Spot is Confirmed!", mail.subject
    assert_equal [@waitlist_golfer.email], mail.to
    assert_match "confirmed", mail.body.encoded.downcase
  end

  test "payment_confirmation_email" do
    @golfer.update!(payment_method: "cash", receipt_number: "TEST123")
    mail = GolferMailer.payment_confirmation_email(@golfer)
    
    assert_equal "Payment Received - Golf Tournament Registration", mail.subject
    assert_equal [@golfer.email], mail.to
  end
end
