class AddNameToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    change_column_null :users, :name, false, "Default User"
  end
end
