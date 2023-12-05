#encoding: utf-8

# == Schema Information
#
# Table name: chapters
#
#  id                      :integer          not null, primary key
#  name                    :string
#  description             :text
#  level                   :integer
#  online                  :boolean          default(FALSE)
#  section_id              :integer
#  nb_tries                :integer          default(0)
#  nb_completions          :integer          default(0)
#  position                :integer          default(0)
#  author                  :string
#  publication_date        :date
#  submission_prerequisite :boolean          default(FALSE)
#
class Chapter < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :section

  has_many :theories, dependent: :destroy
  has_many :questions, dependent: :destroy
  
  has_and_belongs_to_many :users, -> { distinct } # To remember which user has completed which chapter
  has_and_belongs_to_many :problems, -> { distinct } # To remember which problem has which chapter as prerequisite
  has_and_belongs_to_many :creating_users, -> { distinct }, class_name: "User", join_table: :chaptercreations # For a non-admin user to create a chapter

  has_many :prerequisites_associations, class_name: "Prerequisite", dependent: :destroy
  has_many :prerequisites, through: :prerequisites_associations

  has_many :backwards_associations, class_name: "Prerequisite", dependent: :destroy, foreign_key: :prerequisite_id
  has_many :backwards, through: :backwards_associations, source: :chapter

  # VALIDATIONS

  validates :name, presence: true, length: { maximum: 255 }, uniqueness: true
  validates :description, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :level, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 3 }
  
  # OTHER METHODS

  # Total number of prerequisites (with recursion), used to color the prerequisite graph
  def number_prerequisites
    return recursive_prerequisites.size
  end

  # Get all prerequisites (with recursion)
  def recursive_prerequisites
    visited = Set.new
    recursive_prerequisites_aux(self, visited)
    visited.delete(self.id)
    visited.to_a
  end

  private

  # Helper method for recursive_prerequisites
  def recursive_prerequisites_aux(current, visited)
    unless visited.include?(current.id)
      visited.add(current.id)
      current.prerequisites.each do |current_prerequisite|
        recursive_prerequisites_aux(current_prerequisite, visited)
      end
    end
  end
  
  # Update the nb_tries and nb_completions of each chapter (done every monday at 3 am (see schedule.rb))
  # NB: They are more or less maintained correct, but not when a user is deleted for instance
  def self.update_stats
    Chapter.where(:online => true).each do |c|
      nb_tries = Solvedquestion.where(:question => c.questions).distinct.count(:user_id)
      nb_completions = c.users.count
      if c.nb_tries != nb_tries || c.nb_completions != nb_completions
        c.update(:nb_tries => nb_tries, :nb_completions => nb_completions)
      end
    end
  end
end
