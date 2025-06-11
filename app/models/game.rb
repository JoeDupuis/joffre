class Game < ApplicationRecord
  has_secure_password :password, validations: false

  has_many :players, dependent: :destroy
  has_many :users, through: :players

  validates :name, presence: true
  validates :game_code, presence: true, uniqueness: true

  before_validation :generate_game_code, on: :create

  def owner
    players.owner.first&.user
  end

  def password_protected?
    password_digest.present?
  end

  private

  def generate_game_code
    return if game_code.present?

    loop do
      self.game_code = SecureRandom.alphanumeric(6).upcase
      break unless Game.exists?(game_code: game_code)
    end
  end
end
