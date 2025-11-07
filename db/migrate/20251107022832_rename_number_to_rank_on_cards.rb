class RenameNumberToRankOnCards < ActiveRecord::Migration[8.1]
  def change
    rename_column :cards, :number, :rank
  end
end
