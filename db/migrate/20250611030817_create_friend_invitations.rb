class CreateFriendInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :friend_invitations do |t|
      t.references :inviter, null: false, foreign_key: { to_table: :users }
      t.string :invitee_email
      t.integer :status, default: 0, null: false
      t.string :token

      t.timestamps
    end
    add_index :friend_invitations, :token, unique: true
  end
end
