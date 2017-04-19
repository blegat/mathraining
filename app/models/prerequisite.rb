#encoding: utf-8
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

  # BELONGS_TO, HAS_MANY

  belongs_to :prerequisite, class_name: "Chapter"
  belongs_to :chapter

  # VALIDATIONS

  validates :prerequisite_id, presence: true, uniqueness: { scope: :chapter_id }
  validates :chapter_id, presence: true
  
  validate :no_loop
  validate :not_redundant
  validate :create_no_redundance

  # Vérifie qu'il n'y a pas de boucle
  def no_loop
    unless chapter.nil? or prerequisite.nil?
      stack = can_go_from_to(prerequisite, chapter, Set.new)
      unless stack.nil?
        stack.push(chapter.name)
        errors.add(:prerequisite, " : #{prerequisite.name} -> #{chapter.name} forme la boucle #{stack_to_s(stack)}")
      end
    end
  end

  # Vérifie que ce n'est pas redondant
  def not_redundant
    unless chapter.nil? or prerequisite.nil?
      stack = can_go_from_to(chapter, prerequisite, Set.new)
      unless stack.nil?
        errors.add(:prerequisite, " : #{prerequisite.name} -> #{chapter.name} est redondant avec #{stack_to_s(stack)}")
      end
    end
  end

  # Vérifie que ca ne crée pas de redondance
  def create_no_redundance
    unless chapter.nil? or prerequisite.nil?
      targets = Set.new
      recursive_prerequisites(prerequisite, targets)
      stack1 = Array.new
      pre = backward_check(chapter, targets, Set.new, stack1)
      unless pre.nil?
        stack2 = can_go_from_to(prerequisite, pre, Set.new)
        stack = stack2 + stack1.reverse
        back = stack1.first
        errors.add(:prerequisite, " : #{prerequisite.name} -> #{chapter.name} rend #{pre.name} -> #{back} redondant en formant la boucle #{stack_to_s(stack)}. Veuillez supprimer ce lien avant de rajouter celui-ci.")
      end
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
      return "#{stack_to_s(stack)} -> #{current}"
    end
  end

  def recursive_prerequisites(current, visited)
    unless visited.include?(current)
      # this should always happen since it shouldn't have loop
      # or be redundant
      visited.add(current)
      current.prerequisites.each do |next_chapter|
        recursive_prerequisites(next_chapter, visited)
      end
    end
  end

  def backward_check(current, targets, visited, stack)
    if visited.include?(current.id)
      return nil
    end
    visited.add(current.id)

    current.prerequisites.each do |pre|
      if targets.include?(pre)
        stack.push(current.name)
        return pre
      end
    end
    current.backwards.each do |next_chapter|
      pre = backward_check(next_chapter, targets, visited, stack)
      unless pre.nil?
        stack.push(current.name)
        return pre
      end
    end
    return nil
  end
end
