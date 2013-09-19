class Subject < ActiveRecord::Base
  attr_accessible :content, :title, :lastcomment, :admin, :admin_user, :important
  has_many :messages, dependent: :destroy
  belongs_to :user
  belongs_to :chapter
  has_many :subjectfiles, dependent: :destroy
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :user_id, presence: true
  validates :lastcomment, presence: true
end
