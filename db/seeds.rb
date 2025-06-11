# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

if Rails.env.development?
  test_user = User.find_or_create_by!(email_address: "test@example.com") do |user|
    user.name = "Test User"
    user.password = "password"
  end

  friend1 = User.find_or_create_by!(email_address: "friend1@example.com") do |user|
    user.name = "Friend One"
    user.password = "password"
  end

  friend2 = User.find_or_create_by!(email_address: "friend2@example.com") do |user|
    user.name = "Friend Two"
    user.password = "password"
  end

  User.where(user_code: nil).each do |user|
    user.update!(user_code: SecureRandom.alphanumeric(8).upcase)
  end
end
