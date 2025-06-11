require "test_helper"

class CardTest < ActiveSupport::TestCase
  setup do
    @game = Game.create!(name: "Test Game")
    @player = @game.players.create!(user: users(:one), owner: false)
  end

  test "should create card with valid attributes" do
    card = @game.cards.build(color: "red", value: 5, position: 0)
    assert card.valid?
    assert card.save
  end

  test "should require game" do
    card = Card.new(color: "red", value: 5, position: 0)
    assert_not card.valid?
    assert_includes card.errors[:game], "must exist"
  end

  test "should require value" do
    card = @game.cards.build(color: "red", position: 0)
    assert_not card.valid?
    assert_includes card.errors[:value], "can't be blank"
  end

  test "should require color" do
    card = @game.cards.build(value: 5, position: 0)
    assert_not card.valid?
    assert_includes card.errors[:color], "can't be blank"
  end

  test "should require position" do
    card = @game.cards.build(color: "red", value: 5)
    assert_not card.valid?
    assert_includes card.errors[:position], "can't be blank"
  end

  test "value must be between 0 and 7" do
    card = @game.cards.build(color: "red", value: 8, position: 0)
    assert_not card.valid?
    assert_includes card.errors[:value], "is not included in the list"

    card.value = -1
    assert_not card.valid?
    assert_includes card.errors[:value], "is not included in the list"

    card.value = 0
    assert card.valid?

    card.value = 7
    assert card.valid?
  end

  test "position must be unique per game" do
    @game.cards.create!(color: "red", value: 5, position: 0)
    card = @game.cards.build(color: "blue", value: 3, position: 0)
    assert_not card.valid?
    assert_includes card.errors[:position], "has already been taken"
  end

  test "color and value combination must be unique per game" do
    @game.cards.create!(color: "red", value: 5, position: 0)
    assert_raises(ActiveRecord::RecordNotUnique) do
      @game.cards.create!(color: "red", value: 5, position: 1)
    end
  end

  test "sets play bonus for red 0" do
    card = @game.cards.create!(color: "red", value: 0, position: 0)
    assert_equal 5, card.play_bonus
  end

  test "sets play bonus for brown 0" do
    card = @game.cards.create!(color: "brown", value: 0, position: 0)
    assert_equal -3, card.play_bonus
  end

  test "sets play bonus to 0 for other cards" do
    card = @game.cards.create!(color: "blue", value: 3, position: 0)
    assert_equal 0, card.play_bonus
  end

  test "can belong to player" do
    card = @game.cards.create!(color: "red", value: 5, position: 0, owner: @player)
    assert_equal @player, card.owner
    assert card.in_hand?
    assert_not card.in_deck?
    assert_not card.on_table?
  end

  test "in_deck scope and method" do
    deck_card = @game.cards.create!(color: "red", value: 5, position: 10)
    table_card = @game.cards.create!(color: "blue", value: 3, position: 35)
    hand_card = @game.cards.create!(color: "green", value: 2, position: 40, owner: @player)

    assert_includes @game.cards.in_deck, deck_card
    assert_not_includes @game.cards.in_deck, table_card
    assert_not_includes @game.cards.in_deck, hand_card

    assert deck_card.in_deck?
    assert_not table_card.in_deck?
    assert_not hand_card.in_deck?
  end

  test "on_table scope and method" do
    deck_card = @game.cards.create!(color: "red", value: 5, position: 10)
    table_card = @game.cards.create!(color: "blue", value: 3, position: 35)
    hand_card = @game.cards.create!(color: "green", value: 2, position: 40, owner: @player)

    assert_not_includes @game.cards.on_table, deck_card
    assert_includes @game.cards.on_table, table_card
    assert_not_includes @game.cards.on_table, hand_card

    assert_not deck_card.on_table?
    assert table_card.on_table?
    assert_not hand_card.on_table?
  end

  test "create_deck creates 32 cards" do
    @game.create_deck!
    assert_equal 32, @game.cards.count
    assert_equal 8, @game.cards.where(color: "red").count
    assert_equal 8, @game.cards.where(color: "blue").count
    assert_equal 8, @game.cards.where(color: "green").count
    assert_equal 8, @game.cards.where(color: "brown").count
  end

  test "shuffle_deck changes positions" do
    @game.create_deck!
    original_positions = @game.cards.in_deck.pluck(:id, :position).to_h
    @game.shuffle_deck!
    new_positions = @game.cards.in_deck.pluck(:id, :position).to_h

    assert_not_equal original_positions, new_positions
    assert_equal original_positions.keys.sort, new_positions.keys.sort
    assert_equal (0..31).to_a, new_positions.values.sort
  end
end
