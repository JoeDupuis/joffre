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

  test "should create invitation" do
    assert_difference("FriendInvitation.count") do
      post friend_invitations_url, params: { friend_invitation: { invitee_email: "new_friend@example.com" } }
    end

    assert_redirected_to friends_url
  end

  test "should redirect to login when not authenticated" do
    sign_out
    get friend_invitations_url
    assert_redirected_to new_session_url
  end
end
