require "test_helper"

class FriendInvitationMailerTest < ActionMailer::TestCase
  test "invite" do
    invitation = friend_invitations(:one)
    mail = FriendInvitationMailer.invite(invitation)
    assert_equal "#{invitation.inviter.name} wants to be your friend on Joffre", mail.subject
    assert_equal [ invitation.invitee_email ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match invitation.inviter.name, mail.body.encoded
    assert_match invitation.inviter.user_code, mail.body.encoded
  end
end
