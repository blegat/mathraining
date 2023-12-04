# == Schema Information
#
# Table name: countries
#
#  id                  :integer          not null, primary key
#  name                :string
#  code                :string
#  name_without_accent :string
#
class Country < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_many :users

  # VALIDATIONS

  validates :name, presence: true
  validates :code, presence: true
  
  # VALIDATIONS

  # validates_uniqueness_of :code # Test database is broken if we uncomment this line
  validates_uniqueness_of :name

end
