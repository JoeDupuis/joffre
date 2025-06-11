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

  test "should accept friend request" do
    no_friends = users(:no_friends)
    friendship = Friendship.create!(user: no_friends, friend: @user, pending: true)

    patch friendship_url(friendship)
    assert_redirected_to friendships_url

    friendship.reload
    assert_not friendship.pending

    reciprocal = Friendship.find_by(user: @user, friend: no_friends)
    assert reciprocal
    assert_not reciprocal.pending
  end

  test "should decline friend request" do
    no_friends = users(:no_friends)
    friendship = Friendship.create!(user: no_friends, friend: @user, pending: true)

    assert_difference("Friendship.count", -1) do
      delete friendship_url(friendship)
    end

    assert_redirected_to friendships_url
  end

  test "should cancel sent friend request" do
    no_friends = users(:no_friends)
    friendship = Friendship.create!(user: @user, friend: no_friends, pending: true)

    assert_difference("Friendship.count", -1) do
      delete friendship_url(friendship)
    end

    assert_redirected_to friendships_url
  end

  test "should not accept friend request from unrelated users" do
    stranger1 = User.create!(name: "Stranger 1", email_address: "stranger1@example.com", password: "password")
    stranger2 = User.create!(name: "Stranger 2", email_address: "stranger2@example.com", password: "password")
    
    friendship = Friendship.create!(user: stranger1, friend: stranger2, pending: true)
    
    # The controller should not allow current user to accept a friendship they're not part of
    patch friendship_url(friendship)
    
    # Should get a 404 since the friendship doesn't belong to current user
    assert_response :not_found
    
    # Verify the friendship is still pending
    friendship.reload
    assert friendship.pending
  end

  test "should not delete friend request from unrelated users" do
    stranger3 = User.create!(name: "Stranger 3", email_address: "stranger3@example.com", password: "password")
    stranger4 = User.create!(name: "Stranger 4", email_address: "stranger4@example.com", password: "password")
    
    friendship = Friendship.create!(user: stranger3, friend: stranger4, pending: true)
    
    # The controller should not allow current user to delete a friendship they're not part of
    delete friendship_url(friendship)
    
    # Should get a 404 since the friendship doesn't belong to current user
    assert_response :not_found
    
    # Verify the friendship still exists
    assert Friendship.exists?(friendship.id)
  end






  test "should redirect to login when not authenticated for index" do
    sign_out
    get friendships_url
    assert_redirected_to new_session_url
  end

  test "should redirect to login when not authenticated for new" do
    sign_out
    get new_friendship_url
    assert_redirected_to new_session_url
  end

  test "should redirect to login when not authenticated for create" do
    sign_out
    assert_no_difference("Friendship.count") do
      post friendships_url, params: { friendship: { friend_identifier: "no_friends@example.com" } }
    end
    assert_redirected_to new_session_url
  end

  test "should redirect to login when not authenticated for update" do
    sign_out
    patch friendship_url(friendships(:one))
    assert_redirected_to new_session_url
  end

  test "should redirect to login when not authenticated for destroy" do
    sign_out
    assert_no_difference("Friendship.count") do
      delete friendship_url(friendships(:one))
    end
    assert_redirected_to new_session_url
  end
end
