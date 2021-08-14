# == Schema Information
#
# Table name: countries
#
#  id   :integer          not null, primary key
#  name :string
#  code :string
#
class Country < ActiveRecord::Base
  # BELONGS_TO, HAS_MANY

  has_many :users

  # VALIDATIONS

  validates :name, presence: true
  validates :code, presence: true

end
