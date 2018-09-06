class CreateQuestions < ActiveRecord::Migration[5.0]
  def change
    create_table :questions do |t|
      t.text :statement
      t.boolean :is_qcm
      t.boolean :decimal, default: false
      t.float :answer 
      t.boolean :many_answers, default: false
      t.integer :chapter_id
      t.integer :position
      t.boolean :online, default: false
      t.text :explanation
      t.integer :level, default: 1
      t.integer :nb_tries, default: 0
      t.integer :nb_firstguess, default: 0

      t.timestamps
    end
    
    create_table :items do |t|
      t.string :ans
      t.boolean :ok, default: false
      t.integer :question_id

      t.timestamps
    end
    
    create_table :solvedquestions do |t|
      t.integer :user_id
      t.integer :question_id
      t.float :guess
      t.boolean :correct
      t.integer :nb_guess
      t.datetime :resolutiontime

      t.timestamps
    end
    
    create_table :items_solvedquestions, :id => false do |t|
      t.references :item
      t.references :solvedquestion
    end
    
    add_column :subjects, :question_id, :integer
    
    add_index :items, :question_id
    add_index :questions, :chapter_id
    add_index :solvedquestions, [:user_id, :resolutiontime], order: "DESC"
    add_index :solvedquestions, [:user_id, :question_id], unique: true
    add_index :solvedquestions, :resolutiontime, order: "DESC"
    
    qcm_to_question = Array.new
    Qcm.all.each do |q|
      x = Question.new
      x.statement = q.statement
      x.is_qcm = true
      x.decimal = false
      x.answer = 0
      x.many_answers = q.many_answers
      x.chapter_id = q.chapter_id
      x.position = q.position
      x.created_at = q.created_at
      x.updated_at = q.updated_at
      x.online = q.online
      x.explanation = q.explanation
      x.level = q.level
      x.nb_tries = q.nb_tries
      x.nb_firstguess = q.nb_firstguess
      x.save
      qcm_to_question[q.id] = x.id
    end
    
    exercise_to_question = Array.new
    Exercise.all.each do |e|
      x = Question.new
      x.statement = e.statement
      x.is_qcm = false
      x.decimal = e.decimal
      x.answer = e.answer
      x.many_answers = false
      x.chapter_id = e.chapter_id
      x.position = e.position
      x.created_at = e.created_at
      x.updated_at = e.updated_at
      x.online = e.online
      x.explanation = e.explanation
      x.level = e.level
      x.nb_tries = e.nb_tries
      x.nb_firstguess = e.nb_firstguess
      x.save
      exercise_to_question[e.id] = x.id
    end
    
    choice_to_item = Array.new
    Choice.all.each do |c|
      x = Item.new
      x.ans = c.ans
      x.ok = c.ok
      x.question_id = qcm_to_question[c.qcm_id]
      x.created_at = c.created_at
      x.updated_at = c.updated_at
      x.save
      choice_to_item[c.id] = x.id
    end
    
    Solvedqcm.all.each do |s|
      x = Solvedquestion.new
      x.user_id = s.user_id
      x.question_id = qcm_to_question[s.qcm_id]
      x.guess = 0
      x.correct = s.correct
      x.nb_guess = s.nb_guess
      x.created_at = s.created_at
      x.updated_at = s.updated_at
      x.resolutiontime = s.resolutiontime
      x.save
      
      s.choices.each do |c|
        x.items << Item.find(choice_to_item[c.id])
      end
    end
    
    Solvedexercise.all.each do |s|
      x = Solvedquestion.new
      x.user_id = s.user_id
      x.question_id = exercise_to_question[s.exercise_id]
      x.guess = s.guess
      x.correct = s.correct
      x.nb_guess = s.nb_guess
      x.created_at = s.created_at
      x.updated_at = s.updated_at
      x.resolutiontime = s.resolutiontime
      x.save
    end
    
    Subject.all.each do |s|
      if !s.qcm_id.nil?
        s.question_id = qcm_to_question[s.qcm_id]
      elsif !s.exercise_id.nil?
        s.question_id = exercise_to_question[s.exercise_id]
      end
      s.save
    end
  end
end
