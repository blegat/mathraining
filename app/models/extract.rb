#encoding: utf-8

# == Schema Information
#
# Table name: extracts
#
#  id                  :integer          not null, primary key
#  externalsolution_id :integer
#  text                :string
#
include ApplicationHelper

class Extract < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :externalsolution

  # VALIDATIONS

  validates :text, presence: true, length: { maximum: 255 }
  
  # OTHER METHODS
  
  # Method used to check if this extract is included in a submission or correction content
  def is_included_in(content)
    return content.gsub(" ", "").include?(self.text.gsub(" ", ""))
  end
  
end
