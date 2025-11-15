module GamesHelper
  def card_playable?(game, card)
    return false unless game.playing?
    return false unless Current.player&.active?

    trick = game.current_trick
    playable_card_ids = trick.playable_cards(Current.player).pluck(:id)
    playable_card_ids.include?(card.id)
  end
end
