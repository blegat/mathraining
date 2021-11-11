#encoding: utf-8

# == Schema Information
#
# Table name: chapters
#
#  id               :integer          not null, primary key
#  name             :string
#  description      :text
#  level            :integer
#  created_at       :datetime
#  updated_at       :datetime
#  online           :boolean          default(FALSE)
#  section_id       :integer          default(7)
#  nb_tries         :integer          default(0)
#  nb_solved        :integer          default(0)
#  position         :integer          default(0)
#  author           :string
#  publication_time :date
#
class Chapter < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :section # Chaque chapitre appartient à une unique section
  has_and_belongs_to_many :users, -> { distinct } # Pour retenir quel utilisateur a débloqué quel chapitre
  has_and_belongs_to_many :problems, -> { distinct } # Pour savoir les prérequis de tel problème
  
  has_many :chaptercreations, dependent: :destroy # Création d'un chapitre par un non-admin
  has_many :creating_users, through: :chaptercreations, source: :user

  # Un chapitre a des théories, exercices et qcms
  has_many :theories, dependent: :destroy
  has_many :questions, dependent: :destroy

  # Prérequis des chapitres
  has_many :prerequisites_associations, class_name: "Prerequisite", dependent: :destroy
  has_many :prerequisites, through: :prerequisites_associations

  has_many :backwards_associations, class_name: "Prerequisite", dependent: :destroy, foreign_key: :prerequisite_id
  has_many :backwards, through: :backwards_associations, source: :chapter

  # VALIDATIONS

  validates :name, presence: true, length: { maximum: 255 }, uniqueness: true
  validates :description, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :level, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 3 }

  # Nombre de prérequis (avec récursion)
  def number_prerequisites
    return recursive_prerequisites.size
  end

  # Rend les chapitres qui ne sont pas déjà prérequis de celui-ci
  def available_prerequisites
    exceptions = self.recursive_prerequisites + [self.id]
    # exceptions is never empty so the following line works
    Chapter.where("id NOT IN(?)", exceptions)
  end

  # Calcule tous les prérequis (avec récursion) du chapitre
  def recursive_prerequisites
    visited = Set.new
    recursive_prerequisites_aux(self, visited)
    visited.delete(self.id)
    visited.to_a
  end

  private

  # Auxiliaire à recursive_prerequisites
  def recursive_prerequisites_aux(current, visited)
    unless visited.include?(current.id)
      # this should always happen since it shouldn't have loop or be redundant
      visited.add(current.id)
      current.prerequisites.each do |next_chapter|
        recursive_prerequisites_aux(next_chapter, visited)
      end
    end
  end
   
  # Mets à jour les nb_tries et nb_solved de chaque chapitre (fait tous les lundis à 3 heures du matin (voir schedule.rb))
  # NB: Ils sont plus ou moins maintenus à jour en live, mais pas lorsqu'un utilisateur est supprimé, par exemple
  def self.update_stats
    Chapter.where(:online => true).each do |c|
      c.nb_tries = Solvedquestion.where(:question => c.questions).distinct.count(:user_id)
      c.nb_solved = c.users.count
      c.save
    end
  end
end
