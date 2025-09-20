class AddReviewedToProblem < ActiveRecord::Migration[7.1]
  def change
    add_column :problems, :reviewed, :boolean, :default => false
  end
end
