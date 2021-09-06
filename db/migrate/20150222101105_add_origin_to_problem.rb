class AddOriginToProblem < ActiveRecord::Migration[5.0]
  def change
    add_column :problems, :origin, :string
  end
end
