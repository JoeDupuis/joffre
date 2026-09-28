module GamesHelper
  SEAT_NAME_LENGTH = 14
  FIGURE_PIPS = {
    "blue" => { corner: "M28,44.8 L33,54 H23 Z", medallion: "M100,43.5 L106.5,55 H93.5 Z" },
    "green" => { corner: "M23.5,49.5 A4.5,4.5 0 1 0 32.5,49.5 A4.5,4.5 0 1 0 23.5,49.5 Z", medallion: "M94.5,50 A5.5,5.5 0 1 0 105.5,50 A5.5,5.5 0 1 0 94.5,50 Z" },
    "brown" => { corner: "M24,45.5 H32 V53.5 H24 Z", medallion: "M95,45 H105 V55 H95 Z" },
    "red" => { corner: "M28,45 L32.5,49.5 L28,54 L23.5,49.5 Z", medallion: "M100,44 L106,50 L100,56 L94,50 Z" }
  }.freeze

  def game_password_field(form, method, **options)
    form.text_field method, value: nil, autocomplete: "off", autocapitalize: "off", spellcheck: false, class: "-masked", **options
  end

  def seat_name(player, table)
    return t("games.table.you") if player == table.you

    truncate(player.user.name.squish, length: SEAT_NAME_LENGTH, omission: "…")
  end

  def seat_initial(player)
    player.user.name.strip.first.to_s.upcase
  end

  def suit_name(suite)
    t("games.table.suits.#{suite}")
  end

  def card_label(card)
    t("games.table.card", suit: suit_name(card.suite), rank: card.rank)
  end

  def figure_letter_spacing(name)
    name.length > 7 ? 1.6 : 2.6
  end

  def bid_columns(count)
    if count <= 2 then count
    elsif count <= 4 then 2
    elsif count <= 6 then 3
    else 4
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

  def team_side_class(team, current_player = Current.player)
    return unless current_player&.team

    current_player.team == team ? "-us" : "-them"
  end

  def dev_clickable_player_name(player, game: nil, label: nil)
    name = label || (player.is_a?(Player) ? player.user.name : player.name)
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
