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
end
