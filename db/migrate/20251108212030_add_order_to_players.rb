class AddOrderToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :order, :integer

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE players
          SET "order" = (
            SELECT COUNT(*)
            FROM players p2
            WHERE p2.game_id = players.game_id
            AND p2.id <= players.id
          )
        SQL
      end
    end

    change_column_null :players, :order, false
  end
end
