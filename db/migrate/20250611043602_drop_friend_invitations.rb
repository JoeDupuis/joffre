class DropFriendInvitations < ActiveRecord::Migration[8.1]
  def change
    drop_table :friend_invitations do |t|
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.string :invitee_email
      t.integer :status, default: 0, null: false
      t.string :token
      t.timestamps
    end
  end
end
