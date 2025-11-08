# == Schema Information
#
# Table name: unsolvedquestions
#
#  id              :bigint           not null, primary key
#  user_id         :bigint
#  question_id     :bigint
#  guess           :float
#  nb_guess        :integer
#  last_guess_time :datetime
#
require "spec_helper"

describe Unsolvedquestion, solvedquestion: true do

  let(:sq) { FactoryBot.build(:unsolvedquestion) }

  subject { sq }

  it { should be_valid }
  
  # Guess
  describe "when guess is not present" do
    before { sq.guess = nil }
    it { should_not be_valid }
  end

  # Number of guesses
  describe "when nb_guess is not present" do
    before { sq.nb_guess = nil }
    it { should_not be_valid }
  end
  describe "when nb_guess is 0" do
    before { sq.nb_guess = 0 }
    it { should_not be_valid }
  end
  describe "when nb_guess is negative" do
    before { sq.nb_guess = -1 }
    it { should_not be_valid }
  end
  
  # Last guess time
  describe "when last_guess_time is not present" do
    before { sq.last_guess_time = nil }
    it { should_not be_valid }
  end
end
