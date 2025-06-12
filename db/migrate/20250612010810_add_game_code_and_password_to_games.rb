class AddGameCodeAndPasswordToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :game_code, :string
    add_index :games, :game_code, unique: true
    add_column :games, :password_digest, :string
  end
end
