class CreateFollowings < ActiveRecord::Migration
  def change
    create_table "followings", :force => true do |t|
      t.integer  "submission_id"
      t.integer  "user_id"
      t.boolean  "read"
      t.datetime "created_at",    :null => false
      t.datetime "updated_at",    :null => false
    end

    add_index "followings", ["submission_id", "user_id"], :name => "index_followings_on_submission_id_and_user_id"
  end
end
