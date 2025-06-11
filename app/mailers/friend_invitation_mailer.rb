class FriendInvitationMailer < ApplicationMailer
  def invite(invitation)
    @invitation = invitation
    @inviter = invitation.inviter

    mail(
      to: invitation.invitee_email,
      subject: "#{@inviter.name} wants to be your friend on Joffre"
    )
  end
end
