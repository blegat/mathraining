#encoding: utf-8

# == Schema Information
#
# Table name: fakefiles
#
#  id                 :integer          not null, primary key
#  fakefiletable_type :string
#  fakefiletable_id   :integer
#  file_file_name     :string
#  file_content_type  :string
#  file_file_size     :integer
#  file_updated_at    :datetime
#
class Fakefile < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :fakefiletable, polymorphic: true
end
