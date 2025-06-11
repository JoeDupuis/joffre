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
    assert_difference("Friendship.count") do
      post friendships_url, params: { friendship: { friend_identifier: "no_friends@example.com" } }
    end

    assert_redirected_to friendships_url
  end

  test "should create invitation with friend code" do
    assert_difference("Friendship.count") do
      post friendships_url, params: { friendship: { friend_identifier: "NOFRIEND" } }
    end

    assert_redirected_to friendships_url
  end

  test "should redirect to login when not authenticated" do
    sign_out
    get friendships_url
    assert_redirected_to new_session_url
  end
end
