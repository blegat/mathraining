#encoding: utf-8

# == Schema Information
#
# Table name: discussions
#
#  id                :integer          not null, primary key
#  last_message_time :datetime
#
class Discussion < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_many :links, dependent: :destroy
  has_many :users, through: :links
  has_many :tchatmessages, dependent: :destroy

  # OTHER METHODS
  
  # Get several messages (used in controller and in view)
  def get_some_messages(page, per_page)
    tchatmessages.order("created_at DESC").paginate(page: page, per_page: per_page)
  end
  
  # Get the discussion between two users (or nil if it does not exist)
  def self.get_discussion_between(x, y)
    return Discussion.joins("INNER JOIN links a ON discussions.id = a.discussion_id").joins("INNER JOIN links b ON discussions.id = b.discussion_id").where("a.user_id" => x, "b.user_id" => y).first
  end

end
