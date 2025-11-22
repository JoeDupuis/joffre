module GamesHelper
  def player_positions(player_order, current_player = Current.player)
    return default_positions(player_order) unless current_player && player_order.present?

    current_player_index = player_order.index(current_player)
    return default_positions(player_order) unless current_player_index

    {
      current: current_player,
      partner: player_order[(current_player_index + 2) % 4],
      opponent_left: player_order[(current_player_index + 1) % 4],
      opponent_right: player_order[(current_player_index + 3) % 4]
    }
  end

  private

  def default_positions(player_order)
    return {} unless player_order.count == 4

    {
      current: player_order[0],
      partner: player_order[2],
      opponent_left: player_order[1],
      opponent_right: player_order[3]
    }
  end
end
