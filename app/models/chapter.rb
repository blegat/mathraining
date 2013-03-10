class Chapter < ActiveRecord::Base
  attr_accessible :description, :level, :name
  has_and_belongs_to_many :sections
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: true
  validates :description, length: {maximum: 8000 }
  validates :level, presence: true, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10 }

  has_many :prerequisites_associations, class_name: "Prerequisite"
  has_many :prerequisites, through: :prerequisites_associations

  #has_and_belongs_to_many :prerequisites, join_table: :prerequisites,
    #class_name: "Chapter", foreign_key: "chapter_id",
    #association_foreign_key: "prerequisite_id"
  #It does not check validations
  def available_prerequisites
    rec_pre = self.recursive_prerequisites
    if rec_pre.empty?
      Chapter.all
    else
      Chapter.where("id NOT IN(?)", rec_pre + [self.id])
    end
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
