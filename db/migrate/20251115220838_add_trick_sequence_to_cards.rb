class AddTrickSequenceToCards < ActiveRecord::Migration[8.1]
  def change
    add_column :cards, :trick_sequence, :integer
    add_index :cards, [ :trick_id, :trick_sequence ], unique: true
  end
end
