class AddUserCodeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :user_code, :string
    add_index :users, :user_code, unique: true

    reversible do |dir|
      dir.up do
        User.find_each do |user|
          user.update!(user_code: generate_unique_code)
        end
      end
    end
  end

  private

  def generate_unique_code
    loop do
      code = SecureRandom.alphanumeric(8).upcase
      break code unless User.exists?(user_code: code)
    end
  end
end
