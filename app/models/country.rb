# == Schema Information
#
# Table name: countries
#
#  id                  :integer          not null, primary key
#  code                :string
#  name                :string
#  name_without_accent :string
#
# Indexes
#
#  index_countries_on_name                 (name) UNIQUE
#  index_countries_on_name_without_accent  (name_without_accent)
#
class Country < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_many :users

  # VALIDATIONS

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true #, uniqueness: true # Test database is broken if we impose uniqueness

end
