#encoding: utf-8

# == Schema Information
#
# Table name: takentests
#
#  id             :integer          not null, primary key
#  status         :integer
#  taken_time     :datetime
#  user_id        :integer
#  virtualtest_id :integer
#
# Indexes
#
#  index_takentests_on_user_id                     (user_id)
#  index_takentests_on_user_id_and_virtualtest_id  (user_id,virtualtest_id) UNIQUE
#  index_takentests_on_virtualtest_id              (virtualtest_id)
#
class Takentest < ActiveRecord::Base

  #              :not_started => -1  # used in user.rb (method test_status)
  enum :status, {:in_progress =>  0, # started the test but didn't finish yet
                 :finished    =>  1} # finished the test

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :virtualtest
  has_one :takentestcheck, dependent: :destroy
  
  # BEFORE, AFTER
  
  after_create :create_takentestcheck

  # VALIDATIONS

  validates :taken_time, presence: true
  validates :status, presence: true
  validates :virtualtest_id, uniqueness: { scope: :user_id }
  
  # OTHER METHODS
  
  private
  
  # Create the Takentestcheck associated to this Takentest
  def create_takentestcheck
    Takentestcheck.create(:takentest => self) if self.in_progress?
  end

end
