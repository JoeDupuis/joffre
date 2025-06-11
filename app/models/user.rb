class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :players, dependent: :destroy
  has_many :games, through: :players
  has_many :friendships, dependent: :destroy
  has_many :friends, -> { where(friendships: { pending: false }) }, through: :friendships
  has_many :inverse_friendships, class_name: "Friendship", foreign_key: "friend_id", dependent: :destroy
  has_many :inverse_friends, -> { where(friendships: { pending: false }) }, through: :inverse_friendships, source: :user
  has_many :sent_friend_requests, -> { pending }, class_name: "Friendship", foreign_key: "user_id"
  has_many :received_friend_requests, -> { pending }, class_name: "Friendship", foreign_key: "friend_id"

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

  def invite(invitee)
    # Rate limiting: max 10 invitations per hour
    recent_invitations = sent_friend_requests.where("created_at > ?", 1.hour.ago).count
    if recent_invitations >= 10
      errors.add(:base, "Too many invitations sent. Please wait before sending more.")
      return false
    end

    friendship = friendships.build(friend: invitee, pending: true)
    friendship.save
    friendship
  end

  private

  def generate_user_code
    self.user_code = loop do
      code = SecureRandom.alphanumeric(8).upcase
      break code unless User.exists?(user_code: code)
    end
  end
end
