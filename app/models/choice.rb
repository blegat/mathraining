class Choice < ActiveRecord::Base
  attr_accessible :ans, :ok, :qcm_id
  belongs_to :qcm
  has_and_belongs_to_many :solvedqcm
  validates :ans, presence: true, length: {maximum: 255 }
end
