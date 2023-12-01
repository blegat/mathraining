# == Schema Information
#
# Table name: contestscores
#
#  id         :integer          not null, primary key
#  contest_id :integer
#  user_id    :integer
#  rank       :integer
#  score      :integer
#  medal      :integer
#
require "spec_helper"

describe Contestscore, contest: true do
  let!(:contest) { FactoryGirl.create(:contest) }
  let!(:user) { FactoryGirl.create(:user) }
  let!(:contestscore) { FactoryGirl.build(:contestscore, contest: contest, user: user, rank: 1, score: 7, medal: -1) }

  subject { contestscore }

  it { should be_valid }
  
  # Uniqueness
  describe "when already present" do
    before { FactoryGirl.create(:contestscore, contest: contest, user: user, rank: 2, score: 3, medal: -1) }
    it { should_not be_valid }
  end
  
  # Rank
  describe "when rank is not present" do
    before { contestscore.rank = nil }
    it { should_not be_valid }
  end
  
  describe "when rank is zero" do
    before { contestscore.rank = 0 }
    it { should_not be_valid }
  end
  
  # Score
  describe "when score is not present" do
    before { contestscore.score = nil }
    it { should_not be_valid }
  end
  
  describe "when score is 0" do
    before { contestscore.score = 0 }
    it { should_not be_valid }
  end
  
  # Medal
  describe "when medal is not present" do
    before { contestscore.medal = nil }
    it { should_not be_valid }
  end
end
