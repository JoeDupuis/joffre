require "test_helper"

class FriendshipsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  test "should get index" do
    get friendships_url
    assert_response :success
  end

  test "should get new" do
    get new_friendship_url
    assert_response :success
  end

  test "should create invitation with email" do
    # Create a new user that's not already friends with user :one
    new_user = User.create!(name: "New Friend", email_address: "new_friend@example.com", password: "password", user_code: "NEWFRIEND")

    assert_difference("Friendship.count") do
      post friendships_url, params: { friendship: { friend_identifier: "new_friend@example.com" } }
    end

    assert_redirected_to friendships_url
  end

  test "should create invitation with friend code" do
    # Create a new user that's not already friends with user :one
    new_user = User.create!(name: "Test Friend", email_address: "test_friend@example.com", password: "password", user_code: "TESTCODE")

    assert_difference("Friendship.count") do
      post friendships_url, params: { friendship: { friend_identifier: new_user.user_code } }
    end

    assert_redirected_to friendships_url
  end

  test "should redirect to login when not authenticated" do
    sign_out
    get friendships_url
    assert_redirected_to new_session_url
  end
end
