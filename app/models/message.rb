class Message < ActiveRecord::Base
  attr_accessible :content, :admin_user
  belongs_to :subject
  belongs_to :user
  validates :content, presence: true
  validates :user_id, presence: true
  validates :subject_id, presence: true
end
