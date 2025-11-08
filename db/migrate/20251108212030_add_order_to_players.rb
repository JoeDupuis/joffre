class AddOrderToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :order, :integer
  end
end
