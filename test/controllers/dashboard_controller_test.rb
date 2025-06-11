require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "dashboard requires authentication" do
    get root_url
    assert_redirected_to new_session_path

    sign_in_as(users(:one))
    get root_url
    assert_response :success
  end
end
