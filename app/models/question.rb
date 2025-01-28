# == Schema Information
#
# Table name: questions
#
#  id               :integer          not null, primary key
#  statement        :text
#  is_qcm           :boolean
#  decimal          :boolean          default(FALSE)
#  answer           :float
#  many_answers     :boolean          default(FALSE)
#  chapter_id       :integer
#  position         :integer
#  online           :boolean          default(FALSE)
#  explanation      :text
#  level            :integer          default(1)
#  nb_first_guesses :integer          default(0)
#  nb_correct       :integer          default(0)
#  nb_wrong         :integer          default(0)
#
class Question < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :chapter
  has_many :unsolvedquestions, dependent: :destroy
  has_many :solvedquestions, dependent: :destroy
  has_many :users, through: :solvedquestions
  has_many :items, dependent: :destroy
  has_one :subject

  # VALIDATIONS

  validates :statement, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :explanation, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :answer, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :level, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 4 }

  # OTHER METHODS

  # Return the value of the question
  def value
    return 3*level
  end
  
  # Check if answer given by user is correct-
  def check_answer(unsolvedquestion, params)
    first_sub = unsolvedquestion.nil?

    if self.is_qcm # QCM
      items = []
      good_guess = true
      diff_sub = first_sub
      if self.many_answers # Many answers possible
        answer = (params[:ans].nil? ? {} : params[:ans])

        self.items.each do |c|
          if answer[c.id.to_s] # Answered "true"
            good_guess = false if !c.ok
            diff_sub = true if !diff_sub && !unsolvedquestion.items.exists?(c.id)
            items.push(c)
          else # Answered "false"
            good_guess = false if c.ok
            diff_sub = true if !diff_sub && unsolvedquestion.items.exists?(c.id)
          end
        end

        # If the same answer as the previous one: we don't count it
        if !diff_sub
          return ["skip", "Cette réponse est la même que votre réponse précédente."]
        end

        if good_guess
          return ["correct", nil]
        else
          return ["wrong", items]
        end

      else # Unique answer
        if params[:ans].nil? || params[:ans].keys.size != 1
          return ["skip", "Veuillez cocher une réponse."]
        end
        answer = params[:ans].keys[0].to_i
        
        # If the same answer as the previous one: we don't count it
        if !first_sub && answer == unsolvedquestion.items.first.id
          return ["skip", "Cette réponse est la même que votre réponse précédente."]
        end
        
        rep = self.items.where(:ok => true).first
        
        if rep.id == answer
          return ["correct", nil]
        else
          return ["wrong", [Item.find_by_id(answer)]]
        end
      end
    else # EXERCISE
      guess_str = params[:ans]
      guess_str.gsub!(" ", "") # Remove white spaces (possible after comma for decimal numbers, and possible with "12 345" instead of "12345")
      
      allowed_characters = Set['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-']
      if self.decimal
        allowed_characters.add('.') 
        allowed_characters.add(',')
      end
      
      if guess_str.size() == 0
        return ["skip", "Votre réponse est vide."]
      end
      
      (0..guess_str.size()-1).each do |i|
        if !allowed_characters.include?(guess_str[i])
          return ["skip", "La réponse attendue est un nombre #{self.decimal ? 'réel' : 'entier'}."]
        end
      end
      
      guess = (self.decimal ? guess_str.gsub(",",".").to_f : guess_str.to_i)
      
      if !first_sub && unsolvedquestion.guess == guess
        return ["skip", "Cette réponse est la même que votre réponse précédente."]
      end
      
      if guess.abs() > 1000000000
        return ["skip", "Votre réponse est trop grande (en valeur absolue)."]
      end
      
      correct = (self.decimal ? ((self.answer - guess).abs < 0.001) : (self.answer.to_i == guess))
      if correct
        return ["correct", nil]
      else
        return ["wrong", guess]
      end
    end
  end
  
  # Update the nb_correct, nb_wrong and nb_first_guesses of each question (done every tuesday at 3 am (see schedule.rb))
  # NB: They are more or less maintained correct, but not when a user is deleted for instance
  def self.update_stats
    nb_correct_by_question = Solvedquestion.group(:question_id).count
    nb_wrong_by_question = Unsolvedquestion.group(:question_id).count
    nb_first_guesses_by_question = Solvedquestion.where(:nb_guess => 1).group(:question_id).count
    Question.where(:online => true).each do |q|
      nb_correct = nb_correct_by_question[q.id]
      nb_correct = 0 if nb_correct.nil?
      nb_wrong = nb_wrong_by_question[q.id]
      nb_wrong = 0 if nb_wrong.nil?
      nb_first_guesses = nb_first_guesses_by_question[q.id]
      nb_first_guesses = 0 if nb_first_guesses.nil?
      if q.nb_correct != nb_correct || q.nb_wrong != nb_wrong || q.nb_first_guesses != nb_first_guesses
        q.nb_correct = nb_correct
        q.nb_wrong = nb_wrong
        q.nb_first_guesses = nb_first_guesses
        q.save
      end
    end
  end
end
