class AddNumberToQuestions < ActiveRecord::Migration[8.1]
  def change
    add_column :questions, :number, :integer
    
    up_only do
      Chapter.where(:online => true).each do |c|
        c.renumber_questions
      end
    end
  end
end
