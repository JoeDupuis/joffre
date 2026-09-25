module GamesHelper
  def partner_of(player, player_order)
    return nil unless player && player_order.present?

    player_index = player_order.index(player)
    return nil unless player_index

    player_order[(player_index + 2) % 4]
  end

  def player_label(player, current_player = Current.player)
    return player.user.name unless current_player

    if player == current_player
      "You"
    elsif player == partner_of(current_player, player.game.bidding_order || player.game.play_order)
      player.user.name
    else
      player.user.name
    end
  end

  def team_scores(game)
    [ 1, 2 ].index_with { |team| game.round_scores.select { |score| score.team == team }.sum(&:score) }
  end

  def game_status_text(game)
    scores = team_scores(game)

    if game.pending? && game.players.size == 4
      "Ready to start (4/4 players)"
    elsif game.pending?
      "Waiting for players (#{game.players.size}/4)"
    elsif game.done?
      winner = game.winning_team
      if winner
        loser = winner == 1 ? 2 : 1
        "Finished: Team #{winner} won #{score_text(scores[winner])} to #{score_text(scores[loser])}"
      else
        "Finished: #{score_text(scores[1])} to #{score_text(scores[2])}"
      end
    else
      "#{game.status.humanize}: Team 1 #{score_text(scores[1])} – Team 2 #{score_text(scores[2])}"
    end
  end

  def score_text(value)
    value.negative? ? "−#{value.abs}" : value.to_s
  end

  def signed_points(value)
    return "0" if value.to_i.zero?

    value.negative? ? "−#{value.abs}" : "+#{value}"
  end

  def team_label(team, current_player = Current.player)
    return "Team #{team}" unless current_player

    current_player.team == team ? "Us" : "Them"
  end

  def ordered_teams(current_player = Current.player)
    return [ 1, 2 ] unless current_player&.team

    [ current_player.team, current_player.team == 1 ? 2 : 1 ]
  end

  def dev_clickable_player_name(player, game: nil)
    name = player.is_a?(Player) ? player.user.name : player.name
    game_id = game&.id || (player.is_a?(Player) ? player.game_id : nil)

    if (Rails.env.development? || Rails.env.test?) && game_id
      user_id = player.is_a?(Player) ? player.user_id : player.id
      button_to name, dev_switch_user_path(user_id: user_id, game_id: game_id),
                class: "dev-clickable-name",
                form: { style: "display: inline;" }
    else
      name
    end
  end
end
