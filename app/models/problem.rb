#encoding: utf-8

# == Schema Information
#
# Table name: problems
#
#  id               :integer          not null, primary key
#  statement        :text
#  online           :boolean          default(FALSE)
#  level            :integer
#  explanation      :text             default("")
#  section_id       :integer
#  number           :integer          default(1)
#  virtualtest_id   :integer          default(0)
#  position         :integer          default(0)
#  origin           :string
#  markscheme       :text             default("")
#  nb_solves        :integer          default(0)
#  first_solve_time :datetime
#  last_solve_time  :datetime
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
  validates :nb_solves, presence: true, numericality: { greater_or_equal_to: 0 }

  # Retourne la valeur du problème
  def value
    return 15*level
  end
  
  # Mets à jour nb_solves, first_solve_time, last_solve_time de chaque problème (fait tous les mercredis à 3 heures du matin (voir schedule.rb))
  # NB: Ils sont plus ou moins maintenus à jour en live, mais pas lorsqu'un utilisateur est supprimé, par exemple
  def self.update_stats
    Problem.where(:online => true).each do |p|
      nb_solves = p.solvedproblems.count
      if nb_solves >= 1
        first_solve_time = p.solvedproblems.order(:resolution_time).first.resolution_time
        last_solve_time = p.solvedproblems.order(:resolution_time).last.resolution_time
      else
        first_solve_time = nil
        last_solve_time = nil
      end
      if p.nb_solves != nb_solves or p.first_solve_time != first_solve_time or p.last_solve_time != last_solve_time
        p.nb_solves = nb_solves
        p.first_solve_time = first_solve_time
        p.last_solve_time = last_solve_time
        p.save
      end
    end
  end
end
