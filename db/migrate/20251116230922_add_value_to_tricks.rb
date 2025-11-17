class AddValueToTricks < ActiveRecord::Migration[8.1]
  def change
    add_column :tricks, :value, :integer
  end
end
