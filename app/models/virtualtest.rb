#encoding: utf-8

# == Schema Information
#
# Table name: virtualtests
#
#  id       :integer          not null, primary key
#  duration :integer
#  number   :integer          default(1)
#  status   :integer          default("waiting_publication")
#
class Virtualtest < ActiveRecord::Base

  enum :status, {:waiting_publication => 0, # not shown yet to students
                 :published           => 1} # can be started by students
  # NB: The intention is to add :archived the day we want to archive a test (not implemented today)

  # BELONGS_TO, HAS_MANY

  has_many :problems
  has_many :takentests

  # VALIDATIONS

  validates :duration, presence: true, numericality: { greater_than: 0 }
  validates :number, presence: true, uniqueness: true, numericality: { greater_than: 0 }

end
