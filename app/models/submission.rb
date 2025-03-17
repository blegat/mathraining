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
#  status            :integer          default("waiting")
#  intest            :boolean          default(FALSE)
#  score             :integer          default(-1)
#  last_comment_time :datetime
#  star              :boolean          default(FALSE)
#
class Submission < ActiveRecord::Base
  
  enum status: {:draft           => -1, # draft (only for the student)
                :waiting         =>  0, # waiting for a correction
                :wrong           =>  1, # wrong (and last comment was marked as read)
                :correct         =>  2, # correct
                :wrong_to_read   =>  3, # wrong, but last comment was not read yet
                :plagiarized     =>  4, # plagiarized (cannot submit for 6 months)
                :closed          =>  5, # closed by the corrector (cannot submit for 1 week)
                :waiting_forever =>  6} # waiting for a correction that will never happen

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :problem
  has_many :corrections, dependent: :destroy
  has_many :followings, dependent: :destroy
  has_many :followers, through: :followings, source: :user
  has_many :suspicions, dependent: :destroy
  has_many :starproposals, dependent: :destroy
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy
  
  has_and_belongs_to_many :notified_users, -> { distinct }, class_name: "User", join_table: :notifs
  
  # BEFORE, AFTER
  
  after_create :update_last_comment
  before_destroy { self.notified_users.clear }

  # VALIDATIONS

  validates :user_id, presence: true
  validates :problem_id, presence: true
  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  
  # OTHER METHODS

  # Give the icon for the submission
  def icon
    if self.star
      return star_icon
    else
      if self.correct?
        return v_icon
      elsif self.draft? or self.waiting? or self.waiting_forever?
        return dash_icon
      elsif self.wrong? or self.wrong_to_read?
        return x_icon
      elsif self.plagiarized?
        return warning_icon
      elsif self.closed?
        return blocked_icon
      end
    end
  end
  
  # For a plagiarized or closed submission: when can we submit a new submission?
  def date_new_submission_allowed
    if self.plagiarized?
      return self.last_comment_time.in_time_zone.to_date + 6.months
    elsif self.closed?
      return self.last_comment_time.in_time_zone.to_date + 1.week
    else
      return Date.today - 1.day
    end
  end
  
  # Tell if the submission can be seen by the given user
  def can_be_seen_by(user)
    return true  if user.admin?                     # Admins can see all submissions
    return false if self.draft?                     # Drafts (including submissions in a virtualtest that is in progress) cannot be seen, not even by the user itself
    return true  if self.user == user               # One can always see his own submission
    return false if !user.pb_solved?(self.problem)  # One cannot see other submissions if he didn't solve the problem
    return true  if self.correct?                   # One can see all other correct submissions (if he solved the problem)
    return true  if user.corrector?                 # Corrector can see all (visible) submissions (if he solved the problem)
    return false
  end
  
  # Tell if the submission has had some activity recently
  def has_recent_activity
    return self.last_comment_time + 2.months > DateTime.now
  end
  
  # Update last_comment_time and last_comment_user
  def update_last_comment
    last_correction = self.corrections.order(:created_at).last
    if last_correction.nil?
      self.update(:last_comment_time => self.created_at)
    else
      self.update(:last_comment_time => last_correction.created_at)
    end
  end
  
  # Set status to :waiting or :waiting_forever depending on the user
  def set_waiting_status
    if self.user.has_sanction_of_type(:not_corrected)
      self.waiting_forever!
    else
      self.waiting!
    end
  end
  
  # Mark the submission as correct
  def mark_correct
    u = self.user
    pb = self.problem
    self.correct!
    unless u.pb_solved?(pb)
      # Give points to the user
      Globalstatistic.get.update_after_problem_solved(pb.value)
      if u.student?
        u.update_attribute(:rating, u.rating + pb.value)
        pps = u.pointspersections.where(:section_id => pb.section.id).first
        pps.update_attribute(:points, pps.points + pb.value)
      end
      
      # Create Solvedproblem
      last_user_corr = self.corrections.where(:user => u).order(:created_at).last
      resolution_time = (last_user_corr.nil? ? self.created_at : last_user_corr.created_at)
      Solvedproblem.create(:user            => u,
                           :problem         => pb,
                           :correction_time => DateTime.now,
                           :submission      => self,
                           :resolution_time => resolution_time)
                           
      # Update statistics of pb
      pb.nb_solves += 1
      if pb.first_solve_time.nil? || pb.first_solve_time > resolution_time
        pb.first_solve_time = resolution_time
      end
      if pb.last_solve_time.nil? || pb.last_solve_time < resolution_time
        pb.last_solve_time = resolution_time
      end
      pb.save
    end

    # Delete the drafts of the user to the problem
    draft = pb.submissions.where(:user => u, :status => :draft).first
    if !draft.nil?
      draft.destroy
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
        if u.student?
          u.update_attribute(:rating, u.rating - pb.value)
          pps = Pointspersection.where(:user => u, :section_id => pb.section).first
          pps.update_attribute(:points, pps.points - pb.value)
        end
        Globalstatistic.get.update_after_problem_unsolved(pb.value)
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
