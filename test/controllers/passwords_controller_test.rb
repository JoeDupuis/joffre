require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "should get new password reset form when not authenticated" do
    get new_password_url
    assert_response :success
  end

  test "should get edit password form with valid token" do
    token = @user.generate_token_for(:password_reset)
    get edit_password_url(token: token)
    assert_response :success
  end

  test "authenticated user can access password functionality" do
    login @user

    token = @user.generate_token_for(:password_reset)
    get edit_password_url(token: token)
    assert_response :success
  end
end
