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


  # Game 1 ready to start
  game = Game.find_or_create_by!(name: "Alice's Game") do |g|
    g.status = :pending
  end

  alice_owner = Player.find_or_create_by!(user: alice, game: game) do |p|
    p.owner = true
    p.team = 1
  end

  alice_owner.update!(dealer: true) unless game.players.dealer.exists?

  Player.find_or_create_by!(user: bob, game: game) do |p|
    p.team = 1
  end

  Player.find_or_create_by!(user: carol, game: game) do |p|
    p.team = 2
  end

  Player.find_or_create_by!(user: david, game: game) do |p|
    p.team = 2
  end

  # Game 2 only 1 bid left to play
  bidding_game = Game.find_or_create_by!(name: "Bidding Game") do |g|
    g.status = :pending
  end

  alice_player = Player.find_or_create_by!(user: alice, game: bidding_game) do |p|
    p.owner = true
    p.team = 1
  end

  alice_player.update!(dealer: true) unless bidding_game.players.dealer.exists?

  bob_player = Player.find_or_create_by!(user: bob, game: bidding_game) do |p|
    p.team = 1
  end

  carol_player = Player.find_or_create_by!(user: carol, game: bidding_game) do |p|
    p.team = 2
  end

  david_player = Player.find_or_create_by!(user: david, game: bidding_game) do |p|
    p.team = 2
  end

  if bidding_game.pending?
    bidding_game.update!(status: :bidding)
  end

  if bidding_game.bids.empty?
    Bid.create!(game: bidding_game, player: carol_player, amount: 7)
    Bid.create!(game: bidding_game, player: bob_player, amount: nil)
    Bid.create!(game: bidding_game, player: david_player, amount: 8)
  end

  # Game 3 - Almost complete, last card of last trick
  almost_done_game = Game.find_by(name: "Almost Done Game")
  if almost_done_game
    almost_done_game.destroy
  end

  almost_done_game = Game.create!(name: "Almost Done Game", status: :pending)

  if almost_done_game
    alice_p = Player.create!(user: alice, game: almost_done_game, owner: true, dealer: true, team: 1, order: 1)
    bob_p = Player.create!(user: bob, game: almost_done_game, team: 2, order: 2)
    carol_p = Player.create!(user: carol, game: almost_done_game, team: 1, order: 3)
    david_p = Player.create!(user: david, game: almost_done_game, team: 2, order: 4)

    # Update to bidding to allow creating bids
    almost_done_game.update_column(:status, Game.statuses[:bidding])

    Bid.create!(game: almost_done_game, player: bob_p, amount: nil)
    Bid.create!(game: almost_done_game, player: carol_p, amount: 7)
    Bid.create!(game: almost_done_game, player: david_p, amount: nil)
    Bid.create!(game: almost_done_game, player: alice_p, amount: 8)

    # Now update to playing
    almost_done_game.update_column(:status, Game.statuses[:playing])

    players_array = [ alice_p, bob_p, carol_p, david_p ]

    all_cards = []
    Card.suites.each_key do |suite_name|
      (0..7).each do |rank|
        all_cards << { suite: suite_name, rank: rank }
      end
    end
    all_cards.shuffle!

    cards_with_players = all_cards.map.with_index do |card_data, index|
      { **card_data, player: players_array[index % 4] }
    end

    # Create 7 completed tricks (28 cards)
    7.times do |trick_num|
      trick = Trick.create!(game: almost_done_game, winner: alice_p, completed: true)
      4.times do |card_in_trick|
        card_index = trick_num * 4 + card_in_trick
        card_data = cards_with_players[card_index]
        Card.create!(
          game: almost_done_game,
          player: card_data[:player],
          suite: card_data[:suite],
          rank: card_data[:rank],
          trick: trick
        )
      end
    end

    # Create 8th trick with 3 cards
    last_trick = Trick.create!(game: almost_done_game, winner: nil, completed: false)
    3.times do |card_in_trick|
      card_index = 28 + card_in_trick
      card_data = cards_with_players[card_index]
      Card.create!(
        game: almost_done_game,
        player: card_data[:player],
        suite: card_data[:suite],
        rank: card_data[:rank],
        trick: last_trick
      )
    end

    # Create the last card (card 32) without a trick - it's still in hand
    last_card_data = cards_with_players[31]
    Card.create!(
      game: almost_done_game,
      player: last_card_data[:player],
      suite: last_card_data[:suite],
      rank: last_card_data[:rank]
    )
  end
end
