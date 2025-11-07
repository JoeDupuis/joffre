class Game < ApplicationRecord
  enum :status, { pending: 0, started: 1, done: 2 }
  has_secure_password validations: false
  validates :password, confirmation: true, if: -> { password.present? }

  validate :startable, if: :starting?
  after_update :deal_cards_on_start, if: :just_started?

  has_many :players, dependent: :destroy
  has_many :users, through: :players
  has_many :cards, dependent: :destroy

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

  def deal_cards!
    raise ArgumentError, "Game must have exactly 4 players" unless players.count == 4

    deck = Card.deck
    player_list = players.to_a

    deck.each_with_index do |card_attrs, index|
      player = player_list[index % 4]
      cards.create!(card_attrs.merge(player: player))
    end
  end

  private

  def starting?
    will_save_change_to_status? && status == "started"
  end

  def just_started?
    saved_change_to_status? && status == "started"
  end

  def deal_cards_on_start
    deal_cards!
  end

  def startable
    unless players.count == 4 && status_was == "pending"
      errors.add(:status, :invalid)
      return
    end

    unless players.all? { |p| p.team.present? }
      errors.add(:status, :teams_not_assigned)
      return
    end

    unless players.team_one.count == 2 && players.team_two.count == 2
      errors.add(:status, :teams_not_balanced)
    end
  end

  def generate_game_code
    self.game_code = loop do
      code = SecureRandom.alphanumeric(6).upcase
      break code unless Game.exists?(game_code: code)
    end
  end
end
