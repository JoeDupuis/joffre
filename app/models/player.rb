class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game

  validates :user_id, uniqueness: { scope: :game_id }
  validate :game_not_full, on: :create

  scope :owner, -> { where(owner: true) }

  private

  def game_not_full
    return unless game

    if game.players.count >= 4
      errors.add(:base, "Game is full")
    end
  end
end
