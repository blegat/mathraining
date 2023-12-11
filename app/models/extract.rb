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
  
  # Same as previous one but can be called from somewhere else
  def self.is_included_in(str, substr)
    return self.find_if_included_in(str, substr, false)
  end
  
  # Compute [start, end] interval of a string containing a substring
  def self.find_if_included_in(str, substr, get_location = true)
    str_modified = str.gsub("−", "-") # Should not change the length of the string!
    substr_modified = substr.gsub("−", "-") # Idem
    cleaned_substr = substr_modified.gsub(" ", "").gsub("$", "")
    cleaned_str = str_modified.gsub(" ", "").gsub("$", "")
    start = cleaned_str.index(cleaned_substr)
    
    unless get_location
      return !start.nil?
    end

    if start.nil?
      return nil
    else
      start_real = -1
      i = 0
      while i <= start
        start_real = start_real+1
        start_real = start_real+1 while str_modified[start_real] != cleaned_str[i]
        i = i+1
      end
      stop = start + cleaned_substr.size
      stop_real = start_real
      while i < stop
        stop_real = stop_real+1
        stop_real = stop_real+1 while str_modified[stop_real] != cleaned_str[i]
        i = i+1
      end
      stop_real = stop_real+1
      return [start_real, stop_real]
    end
  end
  
end
