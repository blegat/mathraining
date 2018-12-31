class CreateContests < ActiveRecord::Migration[5.0]
  def change
    create_table :contests do |t|
      t.integer :number
      t.text :description
      t.integer :status, default: 0
    end
    
    create_table :contestorganizations, :id => false do |t|
      t.references :contest
      t.references :user
    end
    
    create_table :followingcontests do |t|
      t.references :contest
      t.references :user
    end
    
    create_table :contestscores do |t|
      t.references :contest
      t.references :user
      t.integer :rank
      t.integer :score
    end
    
    create_table :contestproblems do |t|
      t.references :contest
      t.integer :number
      t.text :statement
      t.string :origin
      t.datetime :start_time
      t.datetime :end_time
      t.integer :status, default: 0
    end
    
    create_table :contestsolutions do |t|
      t.references :contestproblem
      t.references :user
      t.text :content
      t.boolean :official, default: false
      t.boolean :correct, default: false
      t.boolean :star, default: false
      t.integer :reservation, default: 0
      t.boolean :corrected, default: false
    end
    
    create_table :contestcorrections do |t|
      t.references :contestsolution
      t.text :content
    end
    
    create_table :takentestchecks do |t|
      t.references :takentest
    end
    
    create_table :contestproblemchecks do |t|
      t.references :contestproblem
    end
    
    add_column :subjects, :contest_id, :integer
  end
end
