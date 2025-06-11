require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get new when not authenticated" do
    get new_session_url
    assert_response :success
  end

  test "should create session with valid credentials" do
    post session_url, params: { email_address: @user.email_address, password: "password" }
    assert_response :redirect
    assert_equal @user, current_user
  end

  test "should destroy session" do
    login @user
    assert_equal @user, current_user

    delete session_url
    assert_redirected_to new_session_url
    assert_nil current_session
  end

  test "logout helper works correctly" do
    login @user
    assert_equal @user, current_user

    logout
    assert_nil current_session
  end

  test "dev signin signs in the seeded user in development" do
    User.create!(email_address: "test@example.com", password: "password")

    post dev_signin_session_url

    assert_response :redirect
    assert_equal "Signed in as test@example.com (dev mode)", flash[:notice]
  end

  test "dev signin redirects when dev user not found" do
    User.find_by(email_address: "test@example.com")&.destroy

    post dev_signin_session_url

    assert_redirected_to new_session_path
    assert_equal "Dev user not found. Run 'rails db:seed' to create it.", flash[:alert]
  end
end
