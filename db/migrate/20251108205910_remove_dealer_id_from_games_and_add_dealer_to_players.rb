class RemoveDealerIdFromGamesAndAddDealerToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :dealer, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        # Migrate existing dealer relationships
        execute <<-SQL
          UPDATE players
          SET dealer = true
          WHERE id IN (SELECT dealer_id FROM games WHERE dealer_id IS NOT NULL)
        SQL
      end
    end

    remove_reference :games, :dealer, foreign_key: { to_table: :players }
  end
end
