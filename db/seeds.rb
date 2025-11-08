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
  dev_users = [
    { name: "Test User", email: "test@example.com" },
    { name: "Alice Johnson", email: "alice@example.com" },
    { name: "Bob Smith", email: "bob@example.com" },
    { name: "Carol Davis", email: "carol@example.com" },
    { name: "David Wilson", email: "david@example.com" },
    { name: "Eve Brown", email: "eve@example.com" },
    { name: "Friend One", email: "friend1@example.com" },
    { name: "Friend Two", email: "friend2@example.com" }
  ]

  dev_users.each do |user_data|
    User.find_or_create_by!(email_address: user_data[:email]) do |user|
      user.name = user_data[:name]
      user.password = "Xk9#mP7$qR2@"
    end
  end

  alice = User.find_by!(email_address: "alice@example.com")
  bob = User.find_by!(email_address: "bob@example.com")
  carol = User.find_by!(email_address: "carol@example.com")
  david = User.find_by!(email_address: "david@example.com")

  game = Game.find_or_create_by!(name: "Alice's Game") do |g|
    g.status = :pending
  end

  Player.find_or_create_by!(user: alice, game: game) do |p|
    p.owner = true
    p.team = 1
  end

  Player.find_or_create_by!(user: bob, game: game) do |p|
    p.team = 1
  end

  Player.find_or_create_by!(user: carol, game: game) do |p|
    p.team = 2
  end

  Player.find_or_create_by!(user: david, game: game) do |p|
    p.team = 2
  end

  # Create a game in bidding phase with 3 bids already placed
  bidding_game = Game.find_or_create_by!(name: "Bidding Game")

  alice_player = Player.find_or_create_by!(user: alice, game: bidding_game) do |p|
    p.owner = true
    p.team = 1
  end

  bob_player = Player.find_or_create_by!(user: bob, game: bidding_game) do |p|
    p.team = 1
  end

  carol_player = Player.find_or_create_by!(user: carol, game: bidding_game) do |p|
    p.team = 2
  end

  david_player = Player.find_or_create_by!(user: david, game: bidding_game) do |p|
    p.team = 2
  end

  # Transition to bidding phase (this will set dealer and deal cards)
  if bidding_game.pending?
    bidding_game.update!(status: :bidding)
  end

  # Create bids: Carol (7), Bob (pass), David (8)
  # Bidding order: Carol, Bob, David, Alice (waiting for Alice's bid)
  if bidding_game.bids.empty?
    Bid.create!(game: bidding_game, player: carol_player, amount: 7)
    Bid.create!(game: bidding_game, player: bob_player, amount: nil)
    Bid.create!(game: bidding_game, player: david_player, amount: 8)
  end

  # Create a second game in bidding phase with 3 bids already placed
  eve = User.find_by!(email_address: "eve@example.com")
  friend1 = User.find_by!(email_address: "friend1@example.com")
  friend2 = User.find_by!(email_address: "friend2@example.com")

  bidding_game2 = Game.find_or_create_by!(name: "Alice's Second Game")

  alice_player2 = Player.find_or_create_by!(user: alice, game: bidding_game2) do |p|
    p.owner = true
    p.team = 1
  end

  eve_player = Player.find_or_create_by!(user: eve, game: bidding_game2) do |p|
    p.team = 1
  end

  friend1_player = Player.find_or_create_by!(user: friend1, game: bidding_game2) do |p|
    p.team = 2
  end

  friend2_player = Player.find_or_create_by!(user: friend2, game: bidding_game2) do |p|
    p.team = 2
  end

  # Transition to bidding phase (this will set dealer and deal cards)
  if bidding_game2.pending?
    bidding_game2.update!(status: :bidding)
  end

  # Create bids: Friend1 (6), Eve (pass), Friend2 (9)
  # Bidding order: Friend1, Eve, Friend2, Alice (waiting for Alice's bid)
  if bidding_game2.bids.empty?
    Bid.create!(game: bidding_game2, player: friend1_player, amount: 6)
    Bid.create!(game: bidding_game2, player: eve_player, amount: nil)
    Bid.create!(game: bidding_game2, player: friend2_player, amount: 9)
  end
end
