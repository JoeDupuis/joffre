class AddPendingToFriendships < ActiveRecord::Migration[8.1]
  def change
    add_column :friendships, :pending, :boolean, default: true, null: false
    add_index :friendships, :pending
  end
end
