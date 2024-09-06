class AddSomeIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :suspicions, :created_at, order: "DESC"
    add_index :suspicions, :status
    
    add_index :starproposals, :created_at, order: "DESC"
    add_index :starproposals, :status
    
    add_index :submissions, :last_comment_time, order: "DESC"
  end
end
