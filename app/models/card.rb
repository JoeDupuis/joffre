class Card < ApplicationRecord
  belongs_to :game
  belongs_to :player
  belongs_to :trick, optional: true

  enum :suite, { blue: 0, green: 1, brown: 2, red: 3 }

  validates :suite, presence: true
  validates :rank, presence: true, inclusion: { in: 0..7 }
  validates :suite, uniqueness: { scope: [ :game_id, :rank ] }
  validates :trick_sequence, presence: true, if: :trick_id?
  validates :trick_sequence, inclusion: { in: 1..4 }, allow_nil: true
  validates :trick_sequence, uniqueness: { scope: :trick_id }, allow_nil: true

  scope :in_hand, -> { where(trick_id: nil) }
  scope :played, -> { where.not(trick_id: nil) }

  def playable?
    player.playable_cards.include?(self)
  end

  def self.deck
    cards = []
    suites.each_key do |suite_name|
      (0..7).each do |rank|
        cards << { suite: suite_name, rank: rank }
      end
    end
    cards.shuffle
  end
end
