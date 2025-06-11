class FriendInvitation < ApplicationRecord
  belongs_to :inviter, class_name: "User"

  enum :status, { pending: 0, accepted: 1, declined: 2 }

  validates :invitee_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  scope :active, -> { pending.where("created_at > ?", 30.days.ago) }

  def accept!
    transaction do
      invitee = User.find_by(email_address: invitee_email)
      return false unless invitee

      Friendship.create!(user: inviter, friend: invitee)
      Friendship.create!(user: invitee, friend: inviter)
      accepted!
    end
  end

  private

  def generate_token
    self.token = SecureRandom.urlsafe_base64(32)
  end
end
