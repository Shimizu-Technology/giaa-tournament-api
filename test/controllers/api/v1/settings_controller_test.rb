require "test_helper"

class Api::V1::SettingsControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    @admin = admins(:admin_one)
    @admin.update!(clerk_id: "test_clerk_#{@admin.id}") if @admin.clerk_id.nil?
    authenticate_as(@admin)
  end

  # ==================
  # GET /api/v1/settings
  # ==================

  test "show returns settings" do
    get api_v1_settings_url, headers: auth_headers
    assert_response :success
    
    json = JSON.parse(response.body)
    assert json.key?("max_capacity")
    assert json.key?("registration_open")
    assert json.key?("tournament_entry_fee")
  end

  test "show requires authentication" do
    get api_v1_settings_url
    assert_response :unauthorized
  end

  # ==================
  # PATCH /api/v1/settings
  # ==================

  test "update modifies max_capacity" do
    patch api_v1_settings_url, params: {
      setting: { max_capacity: 100 }
    }, headers: auth_headers
    
    assert_response :success
    
    setting = Setting.instance
    assert_equal 100, setting.max_capacity
  end

  test "update modifies registration_open" do
    patch api_v1_settings_url, params: {
      setting: { registration_open: false }
    }, headers: auth_headers
    
    assert_response :success
    
    setting = Setting.instance
    assert_equal false, setting.registration_open
  end

  test "update modifies tournament_entry_fee" do
    patch api_v1_settings_url, params: {
      setting: { tournament_entry_fee: 15000 }
    }, headers: auth_headers
    
    assert_response :success
    
    setting = Setting.instance
    assert_equal 15000, setting.tournament_entry_fee
  end

  test "update modifies tournament details" do
    patch api_v1_settings_url, params: {
      setting: {
        tournament_year: "2027",
        tournament_name: "New Tournament Name",
        event_date: "January 15, 2027"
      }
    }, headers: auth_headers
    
    assert_response :success
    
    setting = Setting.instance
    assert_equal "2027", setting.tournament_year
    assert_equal "New Tournament Name", setting.tournament_name
    assert_equal "January 15, 2027", setting.event_date
  end

  test "update logs activity" do
    assert_difference "ActivityLog.count", 1 do
      patch api_v1_settings_url, params: {
        setting: { max_capacity: 75 }
      }, headers: auth_headers
    end
    
    log = ActivityLog.last
    assert_equal "settings_updated", log.action
  end
end

