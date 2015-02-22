class AddOriginToProblem < ActiveRecord::Migration
  def change
    add_column :problems, :origin, :string
  end
end
