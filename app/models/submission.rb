#encoding: utf-8

# == Schema Information
#
# Table name: submissions
#
#  id                :integer          not null, primary key
#  problem_id        :integer
#  user_id           :integer
#  content           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  status            :integer          default("waiting")
#  intest            :boolean          default(FALSE)
#  visible           :boolean          default(TRUE)
#  score             :integer          default(-1)
#  last_comment_time :datetime
#  star              :boolean          default(FALSE)
#
class Submission < ActiveRecord::Base
  
  enum status: {:draft         => -1, # draft (only for the student)
                :waiting       =>  0, # waiting for a correction
                :wrong         =>  1, # wrong (and last comment was marked as read)
                :correct       =>  2, # correct
                :wrong_to_read =>  3, # wrong, but last comment was not read yet
                :plagiarized   =>  4} # plagiarized

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :problem
  has_many :corrections, dependent: :destroy
  has_many :followings, dependent: :destroy
  has_many :followers, through: :followings, source: :user
  has_many :notifs, dependent: :destroy
  has_many :suspicions, dependent: :destroy
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :user_id, presence: true
  validates :problem_id, presence: true
  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  
  # OTHER METHODS

  # Give the icon for the submission
  def icon
    if star
      return star_icon
    else
      if correct?
        return v_icon
      elsif draft? or waiting?
        return dash_icon
      elsif wrong? or wrong_to_read?
        return x_icon
      elsif plagiarized?
        return warning_icon
      end
    end
  end
  
  # Mark the submission as wrong
  def mark_incorrect
    u = self.user
    pb = self.problem
    if self.correct?
      self.status = :wrong
      self.star = false
      self.save
      nb_corr = Submission.where(:problem => pb, :user => u, :status => :correct).count
      if nb_corr == 0
        # Si c'était la seule soumission correcte, alors il faut agir et baisser le score
        sp = Solvedproblem.where(:submission => self).first
        sp.destroy unless sp.nil? # Should never be nil, but for security (and for tests)
        if u.active
          u.rating = u.rating - pb.value
          u.save
        end
        pps = Pointspersection.where(:user => u, :section_id => pb.section).first
        pps.points = pps.points - pb.value
        pps.save
      else
        # Si il y a d'autres soumissions il faut peut-être modifier le submission_id du Solvedproblem correspondant
        sp = Solvedproblem.where(:problem => pb, :user => u).first
        if sp.submission == self
          which = -1
          correction_time = nil
          resolution_time = nil
          Submission.where(:problem => pb, :user => u, :status => :correct).each do |s| 
            lastcomm = s.corrections.where("user_id != ?", u.id).order(:created_at).last
            if(which == -1 || lastcomm.created_at < correction_time)
              which = s.id
              correction_time = lastcomm.created_at
              usercomm = s.corrections.where("user_id = ? AND created_at < ?", u.id, correction_time).last
              resolution_time = (usercomm.nil? ? s.created_at : usercomm.created_at)
            end
          end
          sp.submission_id = which
          sp.correction_time = correction_time
          sp.resolution_time = resolution_time
          sp.save
        end
      end
    end
  end
end
