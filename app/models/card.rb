class Card < ApplicationRecord
  belongs_to :game
  belongs_to :player

  enum :suite, { blue: 0, green: 1, brown: 2, red: 3 }

  validates :suite, presence: true
  validates :number, presence: true, inclusion: { in: 0..7 }
  validates :suite, uniqueness: { scope: [ :game_id, :number ] }

  def self.deck
    cards = []
    suites.each_key do |suite_name|
      (0..7).each do |number|
        cards << { suite: suite_name, number: number }
      end
    end
    cards.shuffle
  end
end
