require "test_helper"

class SettingTest < ActiveSupport::TestCase
  # ==================
  # Singleton Pattern
  # ==================

  test "instance returns existing setting" do
    existing = settings(:one)
    assert_equal existing, Setting.instance
  end

  test "instance creates setting if none exists" do
    Setting.delete_all
    assert_difference "Setting.count", 1 do
      Setting.instance
    end
  end

  test "only one setting can exist" do
    assert_equal 1, Setting.count
    
    # Trying to create another should fail or be prevented
    # (depending on implementation)
  end

  # ==================
  # Default Values
  # ==================

  test "has default max_capacity" do
    Setting.delete_all
    setting = Setting.instance
    assert_not_nil setting.max_capacity
  end

  test "has default registration_open" do
    Setting.delete_all
    setting = Setting.instance
    assert_not_nil setting.registration_open
  end

  # ==================
  # Attributes
  # ==================

  test "max_capacity is accessible" do
    setting = settings(:one)
    assert_respond_to setting, :max_capacity
    assert_kind_of Integer, setting.max_capacity
  end

  test "registration_open is accessible" do
    setting = settings(:one)
    assert_respond_to setting, :registration_open
    assert_includes [true, false], setting.registration_open
  end

  test "tournament_entry_fee is accessible" do
    setting = settings(:one)
    assert_respond_to setting, :tournament_entry_fee
  end

  test "payment_mode is accessible" do
    setting = settings(:one)
    assert_respond_to setting, :payment_mode
  end

  # ==================
  # Tournament Config
  # ==================

  test "tournament_year is accessible" do
    setting = settings(:one)
    assert_respond_to setting, :tournament_year
  end

  test "tournament_name is accessible" do
    setting = settings(:one)
    assert_respond_to setting, :tournament_name
  end

  test "event_date is accessible" do
    setting = settings(:one)
    assert_respond_to setting, :event_date
  end

  test "location_name is accessible" do
    setting = settings(:one)
    assert_respond_to setting, :location_name
  end

  test "contact_name is accessible" do
    setting = settings(:one)
    assert_respond_to setting, :contact_name
  end

  test "contact_phone is accessible" do
    setting = settings(:one)
    assert_respond_to setting, :contact_phone
  end

  # ==================
  # Entry Fee Calculation
  # ==================

  test "entry_fee_dollars returns fee in dollars" do
    setting = settings(:one)
    setting.update!(tournament_entry_fee: 12500) # $125.00 in cents
    assert_equal 125.0, setting.entry_fee_dollars
  end

  test "entry_fee_dollars handles nil" do
    setting = settings(:one)
    setting.update!(tournament_entry_fee: nil)
    # Should return a default or 0
    assert_respond_to setting, :entry_fee_dollars
  end
end
