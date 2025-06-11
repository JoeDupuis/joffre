class Player < ApplicationRecord
  belongs_to :user
  belongs_to :game
  has_many :cards, as: :owner, dependent: :nullify

  validates :user_id, uniqueness: { scope: :game_id }

  scope :owner, -> { where(owner: true) }
end
