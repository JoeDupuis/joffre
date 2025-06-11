require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "should redirect to login when not authenticated then succeed when authenticated" do
    get root_url
    assert_redirected_to new_session_path

    sign_in_as(users(:one))
    get root_url
    assert_response :success
  end
end
