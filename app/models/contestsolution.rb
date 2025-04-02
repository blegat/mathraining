#encoding: utf-8

# == Schema Information
#
# Table name: contestsolutions
#
#  id                :integer          not null, primary key
#  contestproblem_id :integer
#  user_id           :integer
#  content           :text
#  official          :boolean          default(FALSE)
#  star              :boolean          default(FALSE)
#  reservation       :integer          default(0)
#  corrected         :boolean          default(FALSE)
#  score             :integer          default(-1)
#
include ApplicationHelper

class Contestsolution < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :contestproblem
  belongs_to :user, optional: true
  has_one :contestcorrection, dependent: :destroy
  
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :contestproblem_id, uniqueness: { scope: :user_id }
  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :score, presence: true, inclusion: { in: [-1, 0, 1, 2, 3, 4, 5, 6, 7] }
  
  # BEFORE, AFTER
  
  after_create :create_correction
  
  # OTHER METHODS
  
  # Give the icon for the solution
  def icon
    if !corrected
      return dash_icon
    else
      if star
        return star_icon
      elsif score == 7
        return v_icon
      else
        return x_icon
      end
    end
  end
  
  private
  
  # Create the correction just after the creation
  def create_correction
    Contestcorrection.create(:contestsolution => self, :content => "-")
  end

end
