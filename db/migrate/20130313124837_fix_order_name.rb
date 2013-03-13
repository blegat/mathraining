class FixOrderName < ActiveRecord::Migration
  def up
    rename_column :theories, :order, :position
  end

  def down
  end
end
