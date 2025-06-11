require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to login when not authenticated" do
    get root_url
    assert_redirected_to new_session_path
  end

  test "should get index when authenticated" do
    sign_in_as(users(:one))
    get root_url
    assert_response :success
  end
end
