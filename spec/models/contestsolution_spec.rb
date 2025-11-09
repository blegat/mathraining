# == Schema Information
#
# Table name: contestsolutions
#
#  id                :integer          not null, primary key
#  contestproblem_id :integer
#  user_id           :integer
#  content           :text
#  official          :boolean          default(FALSE)
#  star              :boolean          default(FALSE)
#  reservation       :integer          default(0)
#  corrected         :boolean          default(FALSE)
#  score             :integer          default(-1)
#
require "spec_helper"

describe Contestsolution, contestsolution: true do
  let!(:contestproblem) { FactoryBot.create(:contestproblem) }
  let!(:user) { FactoryBot.create(:user) }
  let!(:contestsolution) { FactoryBot.build(:contestsolution, contestproblem: contestproblem, user: user) }

  subject { contestsolution }

  it { should be_valid }
  
  # Uniqueness
  describe "when already present" do
    before { FactoryBot.create(:contestsolution, contestproblem: contestproblem, user: user) }
    it { should_not be_valid }
  end
  
  # Content
  describe "when content is not present" do
    before { contestsolution.content = nil }
    it { should_not be_valid }
  end
  
  describe "when content is too long" do
    before { contestsolution.content = "a" * 16001 }
    it { should_not be_valid }
  end
  
  # Score
  describe "when score is -2" do
    before { contestsolution.score = -2 }
    it { should_not be_valid }
  end
  
  describe "when score is 8" do
    before { contestsolution.score = 8 }
    it { should_not be_valid }
  end
  
  # icon
  describe "icon" do
    let!(:sol_waiting) { FactoryBot.create(:contestsolution, corrected: false, score: -1) }
    let!(:sol_star) { FactoryBot.create(:contestsolution, corrected: true, score: 7, star: true) }
    let!(:sol_correct) { FactoryBot.create(:contestsolution, corrected: true, score: 7) }
    let!(:sol_wrong) { FactoryBot.create(:contestsolution, corrected: true, score: 2) }
    specify do
      expect(sol_waiting.icon).to eq(dash_icon)
      expect(sol_star.icon).to eq(star_icon)
      expect(sol_correct.icon).to eq(v_icon)
      expect(sol_wrong.icon).to eq(x_icon)
    end
  end
end
