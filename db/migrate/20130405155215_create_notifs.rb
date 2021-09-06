class CreateNotifs < ActiveRecord::Migration[5.0]
  def change
    create_table :notifs do |t|
      t.references :submission
      t.references :user
      
      t.timestamps
    end
  end
end
