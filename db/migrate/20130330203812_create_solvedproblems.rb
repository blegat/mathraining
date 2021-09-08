class CreateSolvedproblems < ActiveRecord::Migration[5.0]
  def change
    create_table :solvedproblems do |t|
      t.references :problem
      t.references :user

      t.timestamps
    end
    add_column :submissions, :status, :integer, default: 0
  end
end
