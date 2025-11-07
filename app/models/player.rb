class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game
  has_many :cards, dependent: :destroy

  attr_accessor :password

  validates :user_id, uniqueness: { scope: :game_id, message: "are already in this game" }
  validates :game, presence: { message: "invalid game code" }
  validates :team, inclusion: { in: [ 1, 2 ], allow_nil: true }
  validate :game_not_full, on: :create
  validate :correct_password, on: :create, unless: :owner?
  validate :game_not_started, on: :create

  before_create :assign_team

  scope :owner, -> { where(owner: true) }
  scope :team_one, -> { where(team: 1) }
  scope :team_two, -> { where(team: 2) }

  private

  def assign_team
    return unless game

    player_count = game.players.count
    self.team = player_count < 2 ? 1 : 2
  end

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
