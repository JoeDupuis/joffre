class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"

  validates :user_id, uniqueness: { scope: :friend_id }
  validates :friend_id, exclusion: { in: ->(friendship) { [ friendship.user_id ] }, message: "can't be yourself" }

  scope :pending, -> { where(pending: true) }
  scope :accepted, -> { where(pending: false) }

  def accept!
    transaction do
      update!(pending: false)
      # Create reciprocal friendship if it doesn't exist
      unless Friendship.exists?(user: friend, friend: user)
        Friendship.create!(user: friend, friend: user, pending: false)
      else
        Friendship.find_by(user: friend, friend: user)&.update!(pending: false)
      end
    end
  end

  def decline!
    destroy!
  end
end
