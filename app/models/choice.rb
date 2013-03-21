# == Schema Information
#
# Table name: choices
#
#  id         :integer          not null, primary key
#  ans        :string(255)
#  ok         :boolean          default(FALSE)
#  qcm_id     :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Choice < ActiveRecord::Base
  attr_accessible :ans, :ok, :qcm_id
  belongs_to :qcm

  has_and_belongs_to_many :solvedqcm

  validates :qcm_id, presence: true
  validates :ans, presence: true, length: { maximum: 255 }
  validates :ok, inclusion: { in: [true, false] }

end
