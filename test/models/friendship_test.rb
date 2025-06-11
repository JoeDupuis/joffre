require "test_helper"

class FriendshipTest < ActiveSupport::TestCase
  test "should not allow duplicate friendships" do
    user = users(:one)
    friend = users(:no_friends)

    Friendship.create!(user: user, friend: friend)

    duplicate = Friendship.new(user: user, friend: friend)
    assert_not duplicate.valid?
    assert duplicate.errors[:user_id].any?
  end

  test "should not allow self friendship" do
    user = users(:one)

    friendship = Friendship.new(user: user, friend: user)
    assert_not friendship.valid?
    assert friendship.errors[:friend_id].any?
  end

  test "should create pending friendship by default" do
    user = users(:one)
    friend = users(:no_friends)

    friendship = Friendship.create!(user: user, friend: friend)
    assert friendship.pending
  end

  test "accept! should update friendship to not pending" do
    user = users(:one)
    friend = users(:no_friends)

    friendship = Friendship.create!(user: user, friend: friend, pending: true)
    friendship.accept!

    assert_not friendship.pending
  end

  test "accept! should create reciprocal friendship" do
    user = users(:one)
    friend = users(:no_friends)

    friendship = Friendship.create!(user: friend, friend: user, pending: true)

    assert_difference("Friendship.count", 1) do
      friendship.accept!
    end

    reciprocal = Friendship.find_by(user: user, friend: friend)
    assert reciprocal
    assert_not reciprocal.pending
  end

  test "accept! should update existing reciprocal friendship" do
    user = users(:one)
    friend = users(:no_friends)

    existing_reciprocal = Friendship.create!(user: user, friend: friend, pending: true)
    friendship = Friendship.create!(user: friend, friend: user, pending: true)

    assert_no_difference("Friendship.count") do
      friendship.accept!
    end

    existing_reciprocal.reload
    assert_not existing_reciprocal.pending
  end

  test "pending scope returns only pending friendships" do
    user = users(:one)
    friend = users(:no_friends)

    pending = Friendship.create!(user: user, friend: friend, pending: true)
    accepted = Friendship.create!(user: friend, friend: user, pending: false)

    assert_includes Friendship.pending, pending
    assert_not_includes Friendship.pending, accepted
  end

  test "accepted scope returns only accepted friendships" do
    user = users(:one)
    friend = users(:no_friends)

    pending = Friendship.create!(user: user, friend: friend, pending: true)
    accepted = Friendship.create!(user: friend, friend: user, pending: false)

    assert_includes Friendship.accepted, accepted
    assert_not_includes Friendship.accepted, pending
  end
end
