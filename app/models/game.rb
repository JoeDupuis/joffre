class Game < ApplicationRecord
  enum :status, { pending: 0, started: 1, done: 2 }
  has_secure_password validations: false
  validates :password, confirmation: true, if: -> { password.present? }

  validate :startable, if: :starting?

  has_many :players, dependent: :destroy
  has_many :users, through: :players

  validates :name, presence: true
  validates :game_code, presence: true, uniqueness: true

  before_validation :generate_game_code, on: :create

  def owner
    players.owner.first&.user
  end

  def authenticate_for_join(password)
    return true unless password_digest.present?
    authenticate(password)
  end

  private

  def starting?
    will_save_change_to_status? && status == "started"
  end

  def startable
    errors.add(:status, :invalid) unless players.count == 4 && status_was == "pending"
  end

  def generate_game_code
    self.game_code = loop do
      code = SecureRandom.alphanumeric(6).upcase
      break code unless Game.exists?(game_code: code)
    end
  end
end
