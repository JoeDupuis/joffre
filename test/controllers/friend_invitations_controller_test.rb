require "test_helper"

class FriendInvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "should get index" do
    get friend_invitations_url
    assert_response :success
  end

  test "should get new" do
    get new_friend_invitation_url
    assert_response :success
  end

  test "should create invitation with email" do
    assert_difference("FriendInvitation.count") do
      post friend_invitations_url, params: { friend_invitation: { invitee_identifier: "new_friend@example.com" } }
    end

    assert_redirected_to friends_url
  end

  test "should create invitation with friend code" do
    # Create a new user that's not already friends with user :one
    new_user = User.create!(name: "Test Friend", email_address: "test_friend@example.com", password: "password", user_code: "TESTCODE")

    assert_difference("FriendInvitation.count") do
      post friend_invitations_url, params: { friend_invitation: { invitee_identifier: new_user.user_code } }
    end

    assert_redirected_to friends_url
  end

  test "should redirect to login when not authenticated" do
    sign_out
    get friend_invitations_url
    assert_redirected_to new_session_url
  end
end
