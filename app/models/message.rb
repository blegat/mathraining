class Message < ActiveRecord::Base
  attr_accessible :content, :admin_user
  belongs_to :subject
  belongs_to :user
  has_many :messagefiles
  validates :content, presence: true
  validates :user_id, presence: true
  validates :subject_id, presence: true
end
