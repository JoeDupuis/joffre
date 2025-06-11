class AddUserCodeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :user_code, :string
    add_index :users, :user_code, unique: true
  end
end
