class FriendshipsController < ApplicationController
  def index
    @friends = Current.user.all_friends
    @sent_requests = Current.user.sent_friend_requests
    @received_requests = Current.user.received_friend_requests
  end

  def new
    @friendship = Friendship.new
  end

  def create
    identifier = params.dig(:friendship, :friend_identifier)&.strip

    unless identifier.present?
      redirect_to new_friendship_path, alert: "Please enter an email address or friend code"
      return
    end

    target_user = User.by_email_or_code(identifier).first

    unless target_user
      redirect_to new_friendship_path, alert: "User not found with that email or friend code"
      return
    end

    @friendship = Current.user.invite(target_user)

    if @friendship.is_a?(Friendship) && @friendship.persisted?
      redirect_to friendships_path, notice: "Friend request sent to #{target_user.name}"
    else
      @friendship = Friendship.new(friend_identifier: identifier) if @friendship.is_a?(FalseClass)
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @friendship = Current.user.received_friend_requests.find(params[:id])
    @friendship.accept!
    redirect_to friendships_path, notice: "You are now friends with #{@friendship.user.name}"
  end

  def destroy
    @friendship = Current.user.received_friend_requests.find(params[:id])
    @friendship.decline!
    redirect_to friendships_path, notice: "Friend request declined"
  rescue ActiveRecord::RecordNotFound
    @friendship = Current.user.sent_friend_requests.find(params[:id])
    @friendship.destroy
    redirect_to friendships_path, notice: "Friend request cancelled"
  end
end
