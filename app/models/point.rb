#encoding: utf-8
class Point < ActiveRecord::Base
  # attr_accessible :rating, :forumseen

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  
  # VALIDATIONS

  validates :rating, presence: true
end
