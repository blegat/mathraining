#encoding: utf-8

# == Schema Information
#
# Table name: problems
#
#  id             :integer          not null, primary key
#  statement      :text
#  online         :boolean          default(FALSE)
#  level          :integer
#  explanation    :text             default("")
#  section_id     :integer
#  number         :integer          default(1)
#  virtualtest_id :integer          default(0)
#  position       :integer          default(0)
#  origin         :string
#  markscheme     :text             default("")
#  nb_solved      :integer          default(0)
#  first_solved   :datetime
#  last_solved    :datetime
#
include ApplicationHelper

class Problem < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_and_belongs_to_many :chapters, -> {distinct}
  belongs_to :section
  belongs_to :virtualtest, optional: true

  has_many :submissions, dependent: :destroy
  has_many :solvedproblems, dependent: :destroy
  has_many :users, through: :solvedproblems
  has_one :subject

  # VALIDATIONS

  validates :number, presence: true
  validates :statement, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :explanation, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :origin, length: { maximum: 255 }
  validates :level, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 5 }
  validates :nb_solved, presence: true, numericality: { greater_or_equal_to: 0 }

  # Retourne la valeur du problème
  def value
    return 15*level
  end
  
  # Mets à jour nb_solved, first_solved, last_solved de chaque problème (fait tous les mercredis à 3 heures du matin (voir schedule.rb))
  # NB: Ils sont plus ou moins maintenus à jour en live, mais pas lorsqu'un utilisateur est supprimé, par exemple
  def self.update_stats
    Problem.where(:online => true).each do |p|
      nb_solved = p.solvedproblems.count
      if nb_solved >= 1
        first_solved = p.solvedproblems.order(:truetime).first.truetime
        last_solved = p.solvedproblems.order(:truetime).last.truetime
      else
        first_solved = nil
        last_solved = nil
      end
      if p.nb_solved != nb_solved or p.first_solved != first_solved or p.last_solved != last_solved
        p.nb_solved = nb_solved
        p.first_solved = first_solved
        p.last_solved = last_solved
        p.save
      end
    end
  end
end
