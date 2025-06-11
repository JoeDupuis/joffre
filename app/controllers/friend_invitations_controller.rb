class FriendInvitationsController < ApplicationController
  allow_unauthenticated_access only: [ :accept_via_email, :decline_via_email ]

  def index
    @invitations = Current.user.received_invitations
  end

  def new
    @invitation = Current.user.sent_invitations.build
  end

  def create
    @invitation = Current.user.sent_invitations.build(invitation_params)

    if @invitation.save
      FriendInvitationMailer.invite(@invitation).deliver_later
      redirect_to friends_path, notice: "Invitation sent to #{@invitation.invitee_email}"
    else
      render :new, status: :unprocessable_entity
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

  def invitation_params
    params.require(:friend_invitation).permit(:invitee_email)
  end
end
