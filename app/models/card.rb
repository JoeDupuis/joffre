class Card < ApplicationRecord
  belongs_to :game
  belongs_to :owner, polymorphic: true, optional: true

  enum :color, { brown: 0, blue: 1, red: 2, green: 3 }

  validates :value, presence: true, inclusion: { in: 0..7 }
  validates :color, presence: true
  validates :position, presence: true, uniqueness: { scope: :game_id }
  validates :play_bonus, presence: true

  before_validation :set_play_bonus, on: :create

  scope :in_deck, -> { where(owner: nil, position: 0..31) }
  scope :on_table, -> { where(owner: nil).where.not(position: 0..31) }
  scope :in_hand, ->(player) { where(owner: player) }
  scope :ordered, -> { order(:position) }

  def in_deck?
    owner.nil? && position < 32
  end

  def on_table?
    owner.nil? && position >= 32
  end

  def in_hand?
    owner.present?
  end

  private

  def set_play_bonus
    self.play_bonus = if red? && value == 0
      5
    elsif brown? && value == 0
      -3
    else
      0
    end
  end
end
