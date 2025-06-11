class FriendsController < ApplicationController
  allow_unauthenticated_access only: []

  def index
    @friends = Current.user.all_friends
    @sent_invitations = Current.user.sent_invitations.pending
    @received_invitations = Current.user.received_invitations
  end
end
