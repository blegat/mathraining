class CreateNotifs < ActiveRecord::Migration[5.0]
  def change
    create_table :notifs do |t|
      t.references :submission
      t.references :user
      
      t.timestamps
    end
    add_index :notifs, :user_id
  end
end
