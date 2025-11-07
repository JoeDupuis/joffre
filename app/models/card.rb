class Card < ApplicationRecord
  belongs_to :game
  belongs_to :player

  enum :suite, { blue: 0, green: 1, brown: 2, red: 3 }

  validates :suite, presence: true
  validates :number, presence: true, inclusion: { in: 0..7 }
  validates :suite, uniqueness: { scope: [ :game_id, :number ] }

  def self.create_and_deal_for_game(game)
    raise ArgumentError, "Game must have exactly 4 players" unless game.players.count == 4

    cards = []
    suites.each_key do |suite_name|
      (0..7).each do |number|
        cards << { game: game, suite: suite_name, number: number }
      end
    end

    cards.shuffle!
    players = game.players.to_a

    cards.each_with_index do |card_attrs, index|
      player = players[index % 4]
      create!(card_attrs.merge(player: player))
    end
  end
end
