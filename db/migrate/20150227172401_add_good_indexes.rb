class AddGoodIndexes < ActiveRecord::Migration[5.0]
  def change
    remove_index :solvedqcms, :user_id
    add_index :solvedqcms, [:user_id, :resolutiontime], order: "DESC"
    remove_index :solvedqcms, :qcm_id
    add_index :solvedqcms, [:user_id, :qcm_id], unique: true
    remove_index :solvedexercises, :user_id
    add_index :solvedexercises, [:user_id, :resolutiontime], order: "DESC"
    remove_index :solvedexercises, :exercise_id
    add_index :solvedexercises, [:user_id, :exercise_id], unique: true
    add_index :solvedproblems, [:user_id, :resolutiontime], order: "DESC"

    remove_column :sections, :image

    remove_index :followings, [:submission_id, :user_id]

    add_index :takentests, [:user_id, :virtualtest_id], unique: true

    remove_index :points, :user_id
    add_index :points, :user_id, unique: true
  end
end
