class AddScoreModifierToCards < ActiveRecord::Migration[8.1]
  def change
    add_column :cards, :score_modifier, :integer, default: 0, null: false
  end
end
