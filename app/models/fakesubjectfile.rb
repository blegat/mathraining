class Fakesubjectfile < ActiveRecord::Base
  attr_accessible :file_file_name, :file_content_type, :file_file_size, :file_updated_at, :subject_id
  belongs_to :subject
end
