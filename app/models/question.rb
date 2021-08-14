# == Schema Information
#
# Table name: questions
#
#  id            :integer          not null, primary key
#  statement     :text
#  is_qcm        :boolean
#  decimal       :boolean          default(FALSE)
#  answer        :float
#  many_answers  :boolean          default(FALSE)
#  chapter_id    :integer
#  position      :integer
#  online        :boolean          default(FALSE)
#  explanation   :text
#  level         :integer          default(1)
#  nb_tries      :integer          default(0)
#  nb_firstguess :integer          default(0)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Question < ActiveRecord::Base
  # BELONGS_TO, HAS_MANY

  belongs_to :chapter
  has_many :solvedquestions, dependent: :destroy
  has_many :users, through: :solvedquestions
  has_many :items, dependent: :destroy
  has_one :subject

  # VALIDATIONS

  validates :statement, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :explanation, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :answer, presence: true
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :level, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 4 }

  # Retourne la valeur de l'exercice
  def value
    return 3*level
  end
  
  # A utiliser en ligne de commande pour recalculer les nb_tries et nb_firstguess
  def self.compute_stats
    a = Array.new
    Question.where(:online => true).each do |e|
      nb_tries = 0
      nb_firstguess = 0
      e.solvedquestions.each do |s|
        nb_tries = nb_tries+1
        if(s.correct && s.nb_guess == 1)
          nb_firstguess = nb_firstguess+1
        end
      end
      if(e.nb_tries != nb_tries || e.nb_firstguess != nb_firstguess)
        a[e.id] = [e.id, e.nb_tries, nb_tries, e.nb_firstguess, nb_firstguess]
      end
    end
    return a
  end
  
  # A utiliser en ligne de commande après la fonction précédente pour appliquer les changements
  def self.save_stats(a)
    Question.where(:online => true).each do |e|
      if(!a[e.id].nil?)
        e.nb_tries = a[e.id][2]
        e.nb_firstguess = a[e.id][4]
        e.save
      end
    end
  end
end
