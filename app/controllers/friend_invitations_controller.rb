class FriendInvitationsController < ApplicationController

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

    target_user = User.by_email_or_code(identifier).first
    
    if target_user
      handle_existing_user_invitation(target_user)
    else
      # If no user found and it looks like an email, create invitation for future user
      if looks_like_email?(identifier)
        handle_email_invitation(identifier)
      else
        redirect_to new_friend_invitation_path, alert: "User not found with that email or friend code"
      end
    end
  end

  def accept
    @invitation = Current.user.received_invitations.find(params[:id])

    if @invitation.accept!
      redirect_to friends_path, notice: "You are now friends with #{@invitation.inviter.name}"
    else
      redirect_to friend_invitations_path, alert: "Unable to accept invitation"
    end
  end

  def decline
    @invitation = Current.user.received_invitations.find(params[:id])
    @invitation.declined!
    redirect_to friend_invitations_path, notice: "Invitation declined"
  end

  def destroy
    @invitation = Current.user.sent_invitations.find(params[:id])
    @invitation.destroy
    redirect_to friends_path, notice: "Invitation cancelled"
  end

  private

  def looks_like_email?(identifier)
    identifier.include?("@") && identifier.match?(URI::MailTo::EMAIL_REGEXP)
  end

  def handle_email_invitation(email)
    # Create invitation for non-existing user (no email sent)
    @invitation = Current.user.sent_invitations.build(invitee_email: email)

    if @invitation.save
      redirect_to friends_path, notice: "Invitation created for #{email}. They'll see it when they join or log in."
    else
      @invitation.errors.add(:invitee_identifier, @invitation.errors[:invitee_email].first) if @invitation.errors[:invitee_email].any?
      render :new, status: :unprocessable_entity
    end
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
