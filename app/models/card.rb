class Card < ApplicationRecord
  belongs_to :game
  belongs_to :player
  belongs_to :trick, optional: true

  enum :suite, { blue: 0, green: 1, brown: 2, red: 3 }

  validates :suite, presence: true
  validates :rank, presence: true, inclusion: { in: 0..7 }
  validates :suite, uniqueness: { scope: [ :game_id, :rank ] }

  scope :in_hand, -> { where(trick_id: nil) }
  scope :played, -> { where.not(trick_id: nil) }

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
