class AddTeamToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :team, :integer
  end
end
