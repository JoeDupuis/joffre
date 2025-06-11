# Preview all emails at http://localhost:3000/rails/mailers/friend_invitation_mailer
class FriendInvitationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/friend_invitation_mailer/invite
  def invite
    FriendInvitationMailer.invite
  end
end
