#encoding: utf-8

# == Schema Information
#
# Table name: solvedquestions
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  question_id     :integer
#  guess           :float
#  correct         :boolean
#  nb_guess        :integer
#  resolution_time :datetime
#
include ApplicationHelper

class Solvedquestion < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :question
  belongs_to :user
  has_and_belongs_to_many :items
  
  # BEFORE, AFTER
  
  before_destroy { items.clear }

  # VALIDATIONS

  validates :question_id, uniqueness: { scope: :user_id }
  validates :guess, presence: true
  validates :nb_guess, presence: true, numericality: { greater_than_or_equal_to: 1 }
  
  # Find users having solved many questions in a very short amount of time
  def self.detect_suspicious_users
    suspect_time_range = [3.minutes, 10.minutes]
    suspect_num_solves = [5, 8]
    suspect_time_for_one_question = 1.minute
    suspect_num_fast_solves = 10
    
    # Find all resolution times by user during the last day
    end_of_period = Date.today.in_time_zone
    start_of_period = end_of_period - 1.day
    resolution_times_by_user = {}
    Solvedquestion.joins(question: [{chapter: :section}]).where("resolution_time > ? AND resolution_time <= ? AND sections.fondation = ?", start_of_period, end_of_period, false).order(:resolution_time).each do |sq|
      if resolution_times_by_user[sq.user_id].nil?
        resolution_times_by_user[sq.user_id] = [sq.resolution_time]
      else
        resolution_times_by_user[sq.user_id].push(sq.resolution_time)
      end
    end
    
    # Analyze users having solved at least one question, one by one
    suspect_users = Array.new
    resolution_times_by_user.each do |user_id, resolution_times|
      max_num_solves_in_time_range = [0, 0]
      first_to_check = [0, 0]
      num_fast_solves = 0
      fastest_solve = 1.hour
      (0..(resolution_times.size-1)).each do |i|
        (0..(suspect_time_range.size-1)).each do |j|
          while first_to_check[j] < i and resolution_times[first_to_check[j]] < resolution_times[i] - suspect_time_range[j]
            first_to_check[j] += 1
          end
          max_num_solves_in_time_range[j] = [max_num_solves_in_time_range[j], i-first_to_check[j]+1].max
        end
        if i > 0
          fastest_solve = [fastest_solve, resolution_times[i] - resolution_times[i-1]].min
          if resolution_times[i] - resolution_times[i-1] < suspect_time_for_one_question
            num_fast_solves += 1
          end
        end
        
      end
      
      suspect = true
      suspect = false if max_num_solves_in_time_range[0] < suspect_num_solves[0] # solved 5 questions in 3 min
      suspect = false if max_num_solves_in_time_range[1] < suspect_num_solves[1] # solved 8 questions in 10 min
      suspect = false if num_fast_solves < suspect_num_fast_solves               # solved 10 questions in < 1 min
      
      if suspect
        user = User.find(user_id)
        if user.active
          suspect_users.push({:user => user, :num_solves_in_time_range => max_num_solves_in_time_range, :num_fast_solves => num_fast_solves, :fastest_solve => fastest_solve})
        end
      end
    end
    
    # Post message on forum if needed
    if suspect_users.size > 0
      forum_message = "Le " + write_date_only(start_of_period) + ", les utilisateurs suivants ont eu des activités suspectes :\r\n"
      suspect_users.each do |s|
        forum_message += "\r\n[url=" + Rails.application.routes.url_helpers.user_path(s[:user].id) + "]" + s[:user].name + "[/url] a résolu " + s[:num_solves_in_time_range][0].to_s + " exercices en " + (suspect_time_range[0].to_i/60).to_s + " minutes"
        if s[:num_solves_in_time_range][1] > s[:num_solves_in_time_range][0]
          forum_message += " et " + s[:num_solves_in_time_range][1].to_s + " exercices en " + (suspect_time_range[1].to_i/60).to_s + " minutes"
        end
        forum_message += ". "
        forum_message += (s[:user].sex == 0 ? "Il" : "Elle")
        forum_message += " a résolu " + s[:num_fast_solves].to_s + " exercice#{'s' if s[:num_fast_solves] >= 2} après moins d'une minute de réflexion, #{'dont un ' if s[:num_fast_solves] >= 2}" + "en " + s[:fastest_solve].to_i.to_s + " secondes."
      end
      
      subject = Subject.where(:subject_type => :corrector_alerts).first
      if subject.nil?
        Subject.create(:user_id              => 0,
                       :title                => "Comptes suspects",
                       :content              => forum_message,
                       :for_correctors       => true,
                       :subject_type         => :corrector_alerts,
                       :last_comment_time    => DateTime.now,
                       :last_comment_user_id => 0,
                       :category             => Category.where(:name => "Mathraining").first)
      else
        m = Message.create(:user_id    => 0,
                           :subject_id => subject.id,
                           :content    => forum_message)
        subject.update(:last_comment_time => m.created_at,
                       :last_comment_user_id => 0)
      end
    end
  end

end
