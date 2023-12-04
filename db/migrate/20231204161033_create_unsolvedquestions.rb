class CreateUnsolvedquestions < ActiveRecord::Migration[7.0]
  def change
    create_table :unsolvedquestions do |t|
      t.references :user
      t.references :question
      t.float :guess
      t.integer :nb_guess
      t.datetime :last_guess_time
    end
    
    create_table :items_unsolvedquestions, :id => false do |t|
      t.references :item
      t.references :unsolvedquestion
    end
    
    add_index :unsolvedquestions, [:user_id, :question_id], unique: true
    
    up_only do
      Solvedquestion.where(:correct => false).each do |sq|
        usq = Unsolvedquestion.create(:user            => sq.user,
                                      :question        => sq.question,
                                      :guess           => sq.guess,
                                      :nb_guess        => sq.nb_guess,
                                      :last_guess_time => sq.resolution_time)
        
        sq.items.each do |i|
          usq.items << i
        end
      end
      
      Solvedquestion.where(:correct => false).destroy_all
    end
  end
end
