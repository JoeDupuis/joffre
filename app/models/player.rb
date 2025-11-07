class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game
  has_many :cards, dependent: :destroy

  attr_accessor :password

  validates :user_id, uniqueness: { scope: :game_id, message: "are already in this game" }
  validates :game, presence: { message: "invalid game code" }
  validate :game_not_full, on: :create
  validate :correct_password, on: :create, unless: :owner?
  validate :game_not_started, on: :create

  scope :owner, -> { where(owner: true) }

  private

  def game_not_full
    return unless game

    errors.add(:game, :full) if game.players.count >= 4
  end

  def correct_password
    return unless game
    return if game.authenticate_for_join(password)

    errors.add(:password, :invalid)
  end

  def game_not_started
    return unless game

    errors.add(:game, :started) if game.started?
  end
end
