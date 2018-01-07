#encoding: utf-8
# == Schema Information
#
# Table name: fakefiles
#
#  id                  :integer          not null, primary key
#  fakefiletable_id    :integer
#  fakefiletable_type  :string(255)
#  file_file_name      :string(255)
#  file_content_type   :string(255)
#  file_file_size      :integer
#  file_updated_at     :datetime         not null
#

class Fakefile < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :fakefiletable, polymorphic: true
end
