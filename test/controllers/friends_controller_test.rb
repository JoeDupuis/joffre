require "test_helper"

class FriendsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "should get index" do
    get friends_url
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    sign_out
    get friends_url
    assert_redirected_to new_session_url
  end
end
