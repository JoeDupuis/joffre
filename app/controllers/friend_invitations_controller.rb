class FriendInvitationsController < ApplicationController
  allow_unauthenticated_access only: [ :accept_via_email, :decline_via_email ]

  def index
    @invitations = Current.user.received_invitations
  end

  def new
    @invitation = Current.user.sent_invitations.build
  end

  def create
    identifier = params.dig(:friend_invitation, :invitee_identifier)&.strip

    unless identifier.present?
      redirect_to new_friend_invitation_path, alert: "Please enter an email address or friend code"
      return
    end

    if looks_like_email?(identifier)
      handle_email_invitation(identifier)
    else
      handle_friend_code_invitation(identifier.upcase)
    end
  end

  def accept
    @invitation = FriendInvitation.find_by!(token: params[:id])

    if @invitation.accept!
      redirect_to friends_path, notice: "You are now friends with #{@invitation.inviter.name}"
    else
      redirect_to friend_invitations_path, alert: "Unable to accept invitation"
    end
  end

  def decline
    @invitation = FriendInvitation.find_by!(token: params[:id])
    @invitation.declined!
    redirect_to friend_invitations_path, notice: "Invitation declined"
  end

  def destroy
    @invitation = Current.user.sent_invitations.find(params[:id])
    @invitation.destroy
    redirect_to friends_path, notice: "Invitation cancelled"
  end

  def accept_via_email
    @invitation = FriendInvitation.find_by!(token: params[:token])

    invitee = User.find_by(email_address: @invitation.invitee_email)
    unless invitee
      redirect_to new_registration_path,
        notice: "Please create an account with #{@invitation.invitee_email} to accept this invitation"
      return
    end

    if @invitation.accept!
      redirect_to new_session_path, notice: "Friend invitation accepted! Please log in to see your new friend."
    else
      redirect_to new_session_path, alert: "Unable to accept invitation. It may have already been processed."
    end
  end

  def decline_via_email
    @invitation = FriendInvitation.find_by!(token: params[:token])
    @invitation.declined!
    redirect_to new_session_path, notice: "Friend invitation declined."
  end

  private

  def looks_like_email?(identifier)
    identifier.include?("@") && identifier.match?(URI::MailTo::EMAIL_REGEXP)
  end

  def handle_email_invitation(email)
    # Check if user already exists
    existing_user = User.find_by(email_address: email)
    if existing_user
      return handle_existing_user_invitation(existing_user)
    end

    # Create invitation for non-existing user
    @invitation = Current.user.sent_invitations.build(invitee_email: email)

    if @invitation.save
      redirect_to friends_path, notice: "Invitation sent to #{email}. They'll see it when they join or log in."
    else
      @invitation.errors.add(:invitee_identifier, @invitation.errors[:invitee_email].first) if @invitation.errors[:invitee_email].any?
      render :new, status: :unprocessable_entity
    end
  end

  def handle_friend_code_invitation(friend_code)
    friend = User.find_by(user_code: friend_code)
    unless friend
      redirect_to new_friend_invitation_path, alert: "Friend code not found"
      return
    end

    handle_existing_user_invitation(friend)
  end

  def handle_existing_user_invitation(friend)
    if friend == Current.user
      redirect_to new_friend_invitation_path, alert: "You can't invite yourself"
      return
    end

    # Check if already friends
    if Current.user.all_friends.include?(friend)
      redirect_to friends_path, notice: "#{friend.name} is already your friend!"
      return
    end

    # Check if invitation already exists
    existing_invitation = FriendInvitation.pending.find_by(
      inviter: Current.user,
      invitee_email: friend.email_address
    )

    if existing_invitation
      redirect_to friends_path, notice: "You've already sent an invitation to #{friend.name}"
      return
    end

    # Create invitation that user will see in their received invitations
    @invitation = Current.user.sent_invitations.build(invitee_email: friend.email_address)

    if @invitation.save
      redirect_to friends_path, notice: "Invitation sent to #{friend.name}. They'll see it in their Friends page."
    else
      redirect_to new_friend_invitation_path, alert: "Unable to send invitation"
    end
  end

  def invitation_params
    params.require(:friend_invitation).permit(:invitee_identifier)
  end
end
