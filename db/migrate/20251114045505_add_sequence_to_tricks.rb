class AddSequenceToTricks < ActiveRecord::Migration[8.1]
  def change
    add_column :tricks, :sequence, :integer

    reversible do |dir|
      dir.up do
        # Backfill sequences for existing tricks
        execute <<-SQL
          UPDATE tricks
          SET sequence = (
            SELECT COUNT(*)
            FROM tricks t2
            WHERE t2.game_id = tricks.game_id
            AND t2.id <= tricks.id
          )
        SQL
      end
    end

    change_column_null :tricks, :sequence, false
    add_index :tricks, [:game_id, :sequence], unique: true
  end
end
