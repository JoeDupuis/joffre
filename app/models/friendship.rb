class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: "User"

  validates :user_id, uniqueness: { scope: :friend_id }
  validate :no_self_friendship

  private

  def no_self_friendship
    errors.add(:friend_id, "can't be yourself") if user_id == friend_id
  end
end
