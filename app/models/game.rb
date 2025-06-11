class Game < ApplicationRecord
  has_many :players, dependent: :destroy
  has_many :users, through: :players
  has_many :cards, dependent: :destroy

  validates :name, presence: true

  def owner
    players.owner.first&.user
  end

  def create_deck!
    cards.destroy_all
    position = 0

    Card.colors.each_key do |color|
      (0..7).each do |value|
        cards.create!(color: color, value: value, position: position)
        position += 1
      end
    end

    shuffle_deck!
  end

  def shuffle_deck!
    deck_cards = cards.in_deck.to_a
    shuffled_positions = (0...deck_cards.size).to_a.shuffle

    Card.transaction do
      deck_cards.each do |card|
        card.update_column(:position, 999 + card.id)
      end

      deck_cards.each_with_index do |card, index|
        card.update!(position: shuffled_positions[index])
      end
    end
  end
end
