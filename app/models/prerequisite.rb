require 'set'
class Prerequisite < ActiveRecord::Base
  belongs_to :prerequisite, class_name: "Chapter"
  belongs_to :chapter

  validates :prerequisite_id, presence: true,
    uniqueness: {scope: :chapter_id}
  validates :chapter_id, presence: true

  validate :no_loop
  validate :not_redundant
  # need validation to prevent
  # a.prerequisites << b
  # a.prerequisites << c
  # b.prerequisites << c # should not be allowed

  def can_go_from_to(current, target, visited)
    if target == current
      return true
    end
    if visited.include?(current.id)
      return false
    end
    visited.add(current.id)
    current.prerequisites.each do |next_chapter|
      if can_go_from_to(next_chapter, target, visited)
        return true
      end
    end
    return false
  end
  def no_loop
    if can_go_from_to(prerequisite, chapter, Set.new)
      errors.add(:prerequisite, "forme une boucle")
    end
  end
  def not_redundant
    if can_go_from_to(chapter, prerequisite, Set.new)
      errors.add(:prerequisite, "est redondant")
    end
  end
end
