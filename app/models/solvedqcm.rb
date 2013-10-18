class Solvedqcm < ActiveRecord::Base
  attr_accessible :correct, :qcm_id, :nb_guess, :user_id

  belongs_to :qcm
  belongs_to :user
  has_and_belongs_to_many :choices

end
