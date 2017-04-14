#encoding: utf-8
# == Schema Information
#
# Table name: fakesubmissionfiles
#
#  id                :integer          not null, primary key
#  submission_id     :integer
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime         not null
#

class Fakesubmissionfile < ActiveRecord::Base
  # attr_accessible :file_file_name, :file_content_type, :file_file_size, :file_updated_at, :submission_id

  # BELONGS_TO, HAS_MANY

  belongs_to :submission
end
