class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game

  attr_accessor :password

  validates :user_id, uniqueness: { scope: :game_id, message: "already in this game" }
  validates :game, presence: { message: "invalid game code" }
  validate :game_not_full, on: :create
  validate :correct_password, on: :create

  scope :owner, -> { where(owner: true) }

  private

  def game_not_full
    return unless game

    if game.players.count >= 4
      errors.add(:base, "Game is full")
    end
  end

  def correct_password
    return unless game
    return if game.authenticate_for_join(password)

    errors.add(:base, "Invalid password")
  end
end
