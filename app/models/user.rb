class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :players, dependent: :destroy
  has_many :games, through: :players
  has_many :friendships, dependent: :destroy
  has_many :friends, through: :friendships
  has_many :inverse_friendships, class_name: "Friendship", foreign_key: "friend_id", dependent: :destroy
  has_many :inverse_friends, through: :inverse_friendships, source: :user
  has_many :sent_invitations, class_name: "FriendInvitation", foreign_key: "inviter_id", dependent: :destroy
  has_many :received_invitations, -> { pending }, class_name: "FriendInvitation", foreign_key: "invitee_email", primary_key: "email_address"

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_create :generate_user_code

  scope :by_email_or_code, ->(identifier) {
    where(email_address: identifier).or(where(user_code: identifier.upcase))
  }

  def owned_games
    games.joins(:players).where(players: { user_id: id, owner: true })
  end

  def all_friends
    (friends + inverse_friends).uniq
  end

  private

  def generate_user_code
    self.user_code = loop do
      code = SecureRandom.alphanumeric(8).upcase
      break code unless User.exists?(user_code: code)
    end
  end
end
