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
    return Extract.is_included_in(content, self.text)
  end
  
  def self.is_included_in(str, substr)
    return str.gsub(" ", "").gsub("$", "").include?(substr.gsub(" ", "").gsub("$", ""))
  end
  
  def self.find_if_included_in(str, substr)
    cleaned_substr = substr.gsub(" ", "").gsub("$", "")
    cleaned_str = str.gsub(" ", "").gsub("$", "")
    start = cleaned_str.index(cleaned_substr)
    if start.nil?
      return nil
    end
    start_real = -1
    i = 0
    while i <= start
      start_real = start_real+1
      start_real = start_real+1 while str[start_real] != cleaned_str[i]
      i = i+1
    end
    stop = start + cleaned_substr.size
    stop_real = start_real
    while i < stop
      stop_real = stop_real+1
      stop_real = stop_real+1 while str[stop_real] != cleaned_str[i]
      i = i+1
    end
    stop_real = stop_real+1
    return [start_real, stop_real]
  end
  
end
