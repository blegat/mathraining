#encoding: utf-8

# == Schema Information
#
# Table name: puzzles
#
#  id          :bigint           not null, primary key
#  statement   :text
#  code        :string
#  position    :integer
#  explanation :text
#

class Puzzle < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_many :puzzleattempts, dependent: :destroy

  # VALIDATIONS

  validates :statement, presence: true, length: { maximum: 16000 }
  validates :explanation, presence: true, length: { maximum: 16000 }
  validates :position, presence: true, numericality: { greater_than: 0 }
  
  validates_with CodeValidator
  
  # OTHER METHODS
  
  # Start date of puzzles
  def self.start_date
    return (Rails.env.development? ? Time.zone.local(2024, 12, 22, 14, 0, 0) : Time.zone.local(2024, 12, 22, 14, 0, 0))
  end
  
  # End date of puzzles
  def self.end_date
    return (Rails.env.development? ? Time.zone.local(2024, 12, 29, 14, 0, 0) : Time.zone.local(2024, 12, 29, 14, 0, 0))
  end
  
  # Tells if puzzles started
  def self.started?
    return DateTime.now >= self.start_date
  end
  
  # Tells if puzzles ended
  def self.ended?
    return DateTime.now > self.end_date 
  end
  
  # Tells if puzzles started or current user is a root
  def self.started_or_root(user)
    return self.started? || (!user.nil? && user.root?)
  end
  
  # Value of a puzzle solved by n participants
  def self.value_for(n)
    return (100.0 / Math.cbrt(n)).ceil
  end
end
