class FriendInvitationsController < ApplicationController
  allow_unauthenticated_access only: []

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

  private

  def invitation_params
    params.require(:friend_invitation).permit(:invitee_email)
  end
end
