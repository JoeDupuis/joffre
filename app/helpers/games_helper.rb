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
