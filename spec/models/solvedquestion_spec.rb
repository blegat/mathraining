# == Schema Information
#
# Table name: solvedquestions
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  question_id     :integer
#  guess           :float
#  correct         :boolean
#  nb_guess        :integer
#  resolution_time :datetime
#  updated_at      :datetime         not null
#
require "spec_helper"

describe Solvedquestion do

  before { @se = FactoryGirl.build(:solvedquestion) }

  subject { @se }

  it { should respond_to(:question) }
  it { should respond_to(:user) }
  it { should respond_to(:correct) }
  it { should respond_to(:guess) }
  it { should respond_to(:nb_guess) }

  it { should be_valid }

  # Exercise
  describe "when exercise is not present" do
    before { @se.question = nil }
    it { should_not be_valid }
  end

  # User
  describe "when user is not present" do
    before { @se.user = nil }
    it { should_not be_valid }
  end
  
  # Guess
  describe "when guess is not present" do
    before { @se.guess = nil }
    it { should_not be_valid }
  end

  # Nb_guess
  describe "when nb_guess is not present" do
    before { @se.nb_guess = nil }
    it { should_not be_valid }
  end
  describe "when nb_guess is not a number" do
    before { @se.nb_guess = "x" }
    it { should_not be_valid }
  end
  describe "when nb_guess is 0" do
    before { @se.nb_guess = 0 }
    it { should_not be_valid }
  end
  describe "when nb_guess is negative" do
    before { @se.nb_guess = -1 }
    it { should_not be_valid }
  end

end
