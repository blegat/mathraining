class EnsureUniquenessInDatabase < ActiveRecord::Migration[7.1]
  def change
    add_index :chapters, :name, unique: true
    
    remove_index :contests, :number
    add_index :contests, :number, unique: true
  
    remove_index :contestcorrections, :contestsolution_id
    add_index :contestcorrections, :contestsolution_id, unique: true
    
    remove_index :contestproblemchecks, :contestproblem_id
    add_index :contestproblemchecks, :contestproblem_id, unique: true
    
    add_index :contestscores, [:user_id, :contest_id], unique: true
  
    remove_index :contestsolutions, [:contestproblem_id, :user_id]
    add_index :contestsolutions, [:user_id, :contestproblem_id], unique: true
    
    add_index :countries, :name, unique: true
    
    add_index :followings, [:user_id, :submission_id], unique: true
    
    add_index :globalvariables, :key, unique: true
    
    add_index :links, [:user_id, :discussion_id], unique: true
    
    add_index :pointspersections, [:user_id, :section_id], unique: true
    
    add_index :prerequisites, [:chapter_id, :prerequisite_id], unique: true
    
    add_index :problems, :number, unique: true
    
    add_index :puzzleattempts, [:user_id, :puzzle_id], unique: true
    
    remove_index :records, :date
    add_index :records, :date, unique: true
    
    add_index :solvedproblems, [:user_id, :problem_id], unique: true
    
    remove_index :subjects, :question_id
    add_index :subjects, :question_id, unique: true
    remove_index :subjects, :problem_id
    add_index :subjects, :problem_id, unique: true
    remove_index :subjects, :contest_id
    add_index :subjects, :contest_id, unique: true
    
    remove_index :takentestchecks, :takentest_id
    add_index :takentestchecks, :takentest_id, unique: true
    
    remove_index :visitors, :date
    add_index :visitors, :date, unique: true 
  end
end
