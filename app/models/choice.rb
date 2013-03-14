class Choice < ActiveRecord::Base
  attr_accessible :ans, :ok, :qcm_id
  belongs_to :qcm
  validates :ans, presence: true, length: {maximum: 255 }
end
