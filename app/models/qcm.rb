#encoding: utf-8
# == Schema Information
#
# Table name: qcms
#
#  id           :integer          not null, primary key
#  statement    :text
#  many_answers :boolean
#  chapter_id   :integer
#  position     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  online       :boolean          default(FALSE)
#  explanation  :text
#  level        :integer
#

class Qcm < ActiveRecord::Base
  # attr_accessible :many_answers, :position, :statement, :online, :explanation, :level

  # BELONGS_TO, HAS_MANY

  belongs_to :chapter
  has_many :choices, dependent: :destroy
  has_many :solvedqcms, dependent: :destroy
  has_many :users, :through => :solvedqcms
  has_one :subject

  # VALIDATIONS

  validates :statement, presence: true, length: { maximum: 8000 }
  validates :explanation, length: { maximum: 8000 }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :level, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }

  # Retourne la valeur du qcm
  def value
    return 3*level
  end
  
  # A utiliser en ligne de commande pour recalculer les nb_tries et nb_firstguess
  def self.compute_stats
    a = Array.new
    Qcm.where(:online => true).each do |q|
      nb_tries = 0
      nb_firstguess = 0
      q.solvedqcms.each do |s|
        nb_tries = nb_tries+1
        if(s.correct && s.nb_guess == 1)
          nb_firstguess = nb_firstguess+1
        end
      end
      if(q.nb_tries != nb_tries || q.nb_firstguess != nb_firstguess)
        a[q.id] = [q.id, q.nb_tries, nb_tries, q.nb_firstguess, nb_firstguess]
      end
    end
    return a
  end
  
  # A utiliser en ligne de commande après la fonction précédente pour appliquer les changements
  def self.save_stats(a)
    Qcm.where(:online => true).each do |q|
      if(!a[q.id].nil?)
        q.nb_tries = a[q.id][2]
        q.nb_firstguess = a[q.id][4]
        q.save
      end
    end
  end
end
