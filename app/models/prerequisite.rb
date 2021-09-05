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
      stack = can_go_from_to(prerequisite, chapter, Set.new, prerequisite, chapter)
      unless stack.nil?
        stack.push(chapter.name)
        errors.add(:prerequisite, " : #{prerequisite.name} -> #{chapter.name} forme la boucle #{stack_to_s(stack)}")
      end
    end
  end

  # Vérifie que ce n'est pas redondant
  def not_redundant
    unless chapter.nil? or prerequisite.nil?
      stack = can_go_from_to(chapter, prerequisite, Set.new, prerequisite, chapter)
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
      pre = backward_check(chapter, targets, Set.new, stack1, prerequisite, chapter)
      unless pre.nil?
        stack2 = can_go_from_to(prerequisite, pre, Set.new, prerequisite, chapter)
        stack = stack2 + stack1.reverse
        back = stack1.first
        errors.add(:prerequisite, " : #{prerequisite.name} -> #{chapter.name} rend #{pre.name} -> #{back} redondant en formant la boucle #{stack_to_s(stack)}. Veuillez supprimer ce lien avant de rajouter celui-ci.")
      end
    end
  end

  private

  # It seems that, during the validation of chapter.prerequisites << prerequisite, sometimes
  # chapter already has prerequisite in its prerequisites. So we register the new_prerequisite
  # and new_chapter to remember that we cannot use this edge in the graph
  def can_go_from_to(current, target, visited, new_prerequisite, new_chapter)
    if target == current
      return [current.name]
    end
    if visited.include?(current.id)
      return nil
    end
    visited.add(current.id)
    current.prerequisites.each do |next_chapter|
      if current != new_chapter || next_chapter != new_prerequisite
        stack = can_go_from_to(next_chapter, target, visited, new_prerequisite, new_chapter)
        unless stack.nil?
          stack.push(current.name)
          return stack
        end
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

  def backward_check(current, targets, visited, stack, new_prerequisite, new_chapter)
    if visited.include?(current.id)
      return nil
    end
    visited.add(current.id)

    current.prerequisites.each do |pre|
      if targets.include?(pre) && (current != new_chapter || pre != new_prerequisite)
        stack.push(current.name)
        return pre
      end
    end
    current.backwards.each do |next_chapter|
      if current != new_prerequisite || next_chapter != new_chapter
        pre = backward_check(next_chapter, targets, visited, stack, new_prerequisite, new_chapter)
        unless pre.nil?
          stack.push(current.name)
          return pre
        end
      end
    end
    return nil
  end
end
