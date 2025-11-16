class ChangeTrickSequenceUniquenessToRound < ActiveRecord::Migration[8.1]
  def change
    remove_index :tricks, column: [ :game_id, :sequence ], unique: true, name: "index_tricks_on_game_id_and_sequence"
    add_index :tricks, [ :round_id, :sequence ], unique: true
  end
end
