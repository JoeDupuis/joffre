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
  almost_done_game = Game.find_or_create_by!(name: "Almost Done Game") do |g|
    g.status = :pending
  end

  if almost_done_game.players.empty?
    alice_p = Player.create!(user: alice, game: almost_done_game, owner: true, dealer: true, team: 1, order: 1)
    bob_p = Player.create!(user: bob, game: almost_done_game, team: 2, order: 2)
    carol_p = Player.create!(user: carol, game: almost_done_game, team: 1, order: 3)
    david_p = Player.create!(user: david, game: almost_done_game, team: 2, order: 4)
  else
    alice_p = almost_done_game.players.find_by!(user: alice)
    bob_p = almost_done_game.players.find_by!(user: bob)
    carol_p = almost_done_game.players.find_by!(user: carol)
    david_p = almost_done_game.players.find_by!(user: david)
  end

  if almost_done_game.bids.empty?

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
      trick = Trick.create!(game: almost_done_game, winner: alice_p, completed: true, sequence: trick_num + 1)
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
    last_trick = Trick.create!(game: almost_done_game, winner: nil, completed: false, sequence: 8)
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

  # Game 4 - Near Win: Team 1 is at 38 points, about to win with the last card
  near_win_game = Game.find_or_create_by!(name: "Near Win Game") do |g|
    g.status = :pending
  end

  if near_win_game.players.empty?
    alice_nw = Player.create!(user: alice, game: near_win_game, owner: true, dealer: true, team: 1, order: 1)
    bob_nw = Player.create!(user: bob, game: near_win_game, team: 2, order: 2)
    carol_nw = Player.create!(user: carol, game: near_win_game, team: 1, order: 3)
    david_nw = Player.create!(user: david, game: near_win_game, team: 2, order: 4)
  else
    alice_nw = near_win_game.players.find_by!(user: alice)
    bob_nw = near_win_game.players.find_by!(user: bob)
    carol_nw = near_win_game.players.find_by!(user: carol)
    david_nw = near_win_game.players.find_by!(user: david)
  end

  if near_win_game.round_scores.empty?
    # Create previous round scores: Team 1 at 38 points, Team 2 at 25
    RoundScore.create!(game: near_win_game, number: 1, team: 1, score: 20)
    RoundScore.create!(game: near_win_game, number: 1, team: 2, score: 12)
    RoundScore.create!(game: near_win_game, number: 2, team: 1, score: 18)
    RoundScore.create!(game: near_win_game, number: 2, team: 2, score: 13)

    # Update to bidding to allow creating bids
    near_win_game.update_column(:status, Game.statuses[:bidding])

    # Team 1 (Alice) bids 8 and will make it
    Bid.create!(game: near_win_game, player: bob_nw, amount: nil)
    Bid.create!(game: near_win_game, player: carol_nw, amount: 7)
    Bid.create!(game: near_win_game, player: david_nw, amount: nil)
    Bid.create!(game: near_win_game, player: alice_nw, amount: 8)

    # Now update to playing
    near_win_game.update_column(:status, Game.statuses[:playing])

    players_nw = [ alice_nw, bob_nw, carol_nw, david_nw ]

    # Create a specific card setup to ensure Team 1 gets 8 points (with Red Ace)
    all_cards_nw = []
    Card.suites.each_key do |suite_name|
      (0..7).each do |rank|
        all_cards_nw << { suite: suite_name, rank: rank }
      end
    end

    # Shuffle but ensure the Red Ace (red, rank 0) is in a completed trick won by Team 1
    all_cards_nw.shuffle!

    # Find and place the Red Ace in first trick to guarantee +5 bonus
    red_ace_index = all_cards_nw.index { |c| c[:suite] == "red" && c[:rank] == 0 }
    if red_ace_index && red_ace_index > 3
      all_cards_nw[0], all_cards_nw[red_ace_index] = all_cards_nw[red_ace_index], all_cards_nw[0]
    end

    cards_with_players_nw = all_cards_nw.map.with_index do |card_data, index|
      { **card_data, player: players_nw[index % 4] }
    end

    # Create 7 completed tricks, all won by Team 1 (alternating Alice and Carol)
    7.times do |trick_num|
      winner = trick_num.even? ? alice_nw : carol_nw
      trick = Trick.create!(game: near_win_game, winner: winner, completed: true, sequence: trick_num + 1)
      4.times do |card_in_trick|
        card_index = trick_num * 4 + card_in_trick
        card_data = cards_with_players_nw[card_index]
        Card.create!(
          game: near_win_game,
          player: card_data[:player],
          suite: card_data[:suite],
          rank: card_data[:rank],
          trick: trick,
          trick_sequence: card_in_trick + 1
        )
      end
    end

    # Create 8th trick with 3 cards played (Alice's turn next)
    last_trick = Trick.create!(game: near_win_game, winner: nil, completed: false, sequence: 8)
    3.times do |card_in_trick|
      card_index = 28 + card_in_trick
      card_data = cards_with_players_nw[card_index]
      Card.create!(
        game: near_win_game,
        player: card_data[:player],
        suite: card_data[:suite],
        rank: card_data[:rank],
        trick: last_trick,
        trick_sequence: card_in_trick + 1
      )
    end

    # Last card (card 32) in Alice's hand - when she plays it, Team 1 wins the game
    last_card_data = cards_with_players_nw[31]
    Card.create!(
      game: near_win_game,
      player: last_card_data[:player],
      suite: last_card_data[:suite],
      rank: last_card_data[:rank]
    )
  end
end
