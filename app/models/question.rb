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
