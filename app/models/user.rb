# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  first_name      :string(255)
#  last_name       :string(255)
#  email           :string(255)
#  password_digest :string(255)
#  remember_token  :string(255)
#  admin           :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class User < ActiveRecord::Base
  attr_accessible :email, :first_name, :last_name,
    :password, :password_confirmation, :admin,
    :email_confirm, :key, :rating
  has_secure_password
  has_and_belongs_to_many :theories
  has_and_belongs_to_many :chapters, :uniq => true
  has_many :solvedexercises, dependent: :destroy
  has_many :exercises, through: :solvedexercises
  has_many :solvedqcms, dependent: :destroy
  has_many :qcms, through: :solvedqcms
  has_many :solvedproblems, dependent: :destroy
  has_many :problems, through: :solvedproblems

  has_many :pictures

  before_save { self.email.downcase! }
  before_save :create_remember_token

  validates :first_name, presence: true, length: { maximum: 32 }
  validates :last_name, presence: true, length: { maximum: 32 }
  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 0 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },
	  uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }
  # presence: true <- commented to avoid
  # duplication of error message with confirmation
  validates :password_confirmation, presence: true

  def name
    "#{self.first_name} #{self.last_name}"
  end

  def solved?(x)
    return x.users.include?(self)
  end
  private
  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end
end
