class AddSequenceToTricks < ActiveRecord::Migration[8.1]
  def change
    add_column :tricks, :sequence, :integer, null: false
    add_index :tricks, [:game_id, :sequence], unique: true
  end
end
