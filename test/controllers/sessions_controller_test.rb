require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
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
