# == Schema Information
#
# Table name: prerequisites
#
#  id              :integer          not null, primary key
#  prerequisite_id :integer
#  chapter_id      :integer
#

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

  def no_loop
    stack = can_go_from_to(prerequisite, chapter, Set.new)
    unless stack.nil?
      stack.push(chapter.name)
      errors.add(:prerequisite, "#{chapter.name}->#{prerequisite.name} forme la boucle #{stack_to_s(stack)}")
    end
  end
  def not_redundant
    stack = can_go_from_to(chapter, prerequisite, Set.new)
    unless stack.nil?
      errors.add(:prerequisite, "#{chapter.name}->#{prerequisite.name} est redondant avec #{stack_to_s(stack)}")
    end
  end
  private

  def can_go_from_to(current, target, visited)
    if target == current
      return [current.name]
    end
    if visited.include?(current.id)
      return nil
    end
    visited.add(current.id)
    current.prerequisites.each do |next_chapter|
      stack = can_go_from_to(next_chapter, target, visited)
      unless stack.nil?
        stack.push(current.name)
        return stack
      end
    end
    return nil
  end
  def stack_to_s(stack)
    current = stack.pop
    if stack.empty?
      return current
    else
      return "#{current} -> #{stack_to_s(stack)}"
    end
  end
end
