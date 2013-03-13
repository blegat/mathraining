# == Schema Information
#
# Table name: chapters
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  level       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Chapter < ActiveRecord::Base
  attr_accessible :description, :level, :name
  has_and_belongs_to_many :sections
  has_many :theories
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: true
  validates :description, length: { maximum: 8000 }
  validates :level, presence: true, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10 }

  has_many :prerequisites_associations, class_name: "Prerequisite",
    dependent: :destroy
  has_many :prerequisites, through: :prerequisites_associations

  has_many :backwards_associations, class_name: "Prerequisite",
    dependent: :destroy, foreign_key: :prerequisite_id
  has_many :backwards, through: :backwards_associations,
    source: :chapter

  #has_and_belongs_to_many :prerequisites, join_table: :prerequisites,
    #class_name: "Chapter", foreign_key: "chapter_id",
    #association_foreign_key: "prerequisite_id"
  #It does not check validations
  def available_prerequisites
    exceptions = self.recursive_prerequisites + [self.id]
    # exceptions is never empty so the following line works
    Chapter.where("id NOT IN(?)", exceptions)
  end
  def recursive_prerequisites
    visited = Set.new
    recursive_prerequisites_aux(self, visited)
    visited.delete(self.id)
    visited.to_a
  end

  private

  def recursive_prerequisites_aux(current, visited)
    unless visited.include?(current.id)
      # this should always happen since it shouldn't have loop
      # or be redundant
      visited.add(current.id)
      current.prerequisites.each do |next_chapter|
        recursive_prerequisites_aux(next_chapter, visited)
      end
    end
  end
end
