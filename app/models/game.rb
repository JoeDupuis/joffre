class Game < ApplicationRecord
  has_secure_password validations: false
  validates :password, confirmation: true, if: :password_digest_changed?
  
  has_many :players, dependent: :destroy
  has_many :users, through: :players

  validates :name, presence: true
  validates :game_code, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, allow_blank: true

  before_validation :generate_game_code, on: :create

  def owner
    players.owner.first&.user
  end

  private

  def generate_game_code
    self.game_code = loop do
      code = SecureRandom.alphanumeric(6).upcase
      break code unless Game.exists?(game_code: code)
    end
  end
end
