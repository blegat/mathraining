class FixOrderName < ActiveRecord::Migration[5.0]
  def up
    rename_column :theories, :order, :position
  end

  def down
  end
end
