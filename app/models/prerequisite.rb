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
  
  validate :no_loop
  validate :not_redundant
  validate :create_no_redundance
  
  # OTHER METHODS

  # Check that the new connection does not create a loop in the graph
  def no_loop
    unless chapter.nil? or prerequisite.nil?
      # The connection chapter -> prerequisite creates a loop if there is a path from prerequisite to chapter
      path = find_path_from_to(prerequisite, chapter, Set.new)
      unless path.nil?
        path.push(chapter.name)
        errors.add(:prerequisite, " : #{prerequisite.name} -> #{chapter.name} forme la boucle #{path_to_s(path)}")
      end
    end
  end

  # Check that the new connection is not redundant with an existing path
  def not_redundant
    unless chapter.nil? or prerequisite.nil?
      # The connection chapter -> prerequisite if redundant if there is a path from chapter to prerequisite
      path = find_path_from_to(chapter, prerequisite, Set.new)
      unless path.nil?
        errors.add(:prerequisite, " : #{prerequisite.name} -> #{chapter.name} est redondant avec #{path_to_s(path)}")
      end
    end
  end

  # Check that the new connection does not create any redundance in the graph
  def create_no_redundance
    unless chapter.nil? or prerequisite.nil?
      # Put all recursive prerequisites of prerequiste in rec_prerequisites
      rec_prerequisites = Set.new
      recursive_prerequisites(prerequisite, rec_prerequisites)
      # Put all recursive backwards of chapter in rec_backwards
      rec_backwards = Set.new
      recursive_backwards(chapter, rec_backwards)
      # The connection chapter -> prerequisite creates a redundance if there is a direct link from in rec_backwards to rec_prerequisites
      rec_backwards.each do |current|
        current.prerequisites.each do |current_prerequisite|
          unless current == chapter && current_prerequisite == prerequisite
            if rec_prerequisites.include?(current_prerequisite)
              path1 = find_path_from_to(prerequisite, current_prerequisite, Set.new)
              path2 = find_path_from_to(current, chapter, Set.new)
              errors.add(:prerequisite, " : #{prerequisite.name} -> #{chapter.name} rend #{current_prerequisite.name} -> #{current.name} redondant, via le chemin #{path_to_s(path1 + path2)}. Veuillez supprimer ce lien avant de rajouter celui-ci.")
              return
            end
          end
        end
      end
    end
  end

  private

  # Find a path between current and target (or return nil if none)
  # NB: This method ignores the current link chapter -> prerequisite in the graph
  def find_path_from_to(current, target, visited)
    if target == current
      return [current.name]
    end
    unless visited.include?(current.id)
      visited.add(current.id)
      current.prerequisites.each do |next_chapter|
        unless current == chapter && next_chapter == prerequisite
          path = find_path_from_to(next_chapter, target, visited)
          unless path.nil?
            path.push(current.name)
            return path
          end
        end
      end
    end
    return nil
  end

  # Get all prerequisites of current (including itself), not going through already visited ones
  # NB: This method ignores the current link chapter -> prerequisite in the graph
  def recursive_prerequisites(current, visited)
    unless visited.include?(current)
      visited.add(current)
      current.prerequisites.each do |current_prerequisite|
        unless current == chapter && current_prerequisite == prerequisite
          recursive_prerequisites(current_prerequisite, visited)
        end
      end
    end
  end
  
  # Get all backwards of current (including itself), not going through already visited ones
  # NB: This method ignores the current link chapter -> prerequisite in the graph
  def recursive_backwards(current, visited)
    unless visited.include?(current)
      visited.add(current)
      current.backwards.each do |current_backward|
        unless current == prerequisite && current_backward == chapter
          recursive_backwards(current_backward, visited)
        end
      end
    end
  end
  
  # Print a path in a readable string
  def path_to_s(path)
    current = path.pop
    if path.empty?
      return current
    else
      return "#{path_to_s(path)} -> #{current}"
    end
  end
end
