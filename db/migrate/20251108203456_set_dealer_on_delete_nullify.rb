class SetDealerOnDeleteNullify < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :games, :players, column: :dealer_id
    add_foreign_key :games, :players, column: :dealer_id, on_delete: :nullify
  end
end
