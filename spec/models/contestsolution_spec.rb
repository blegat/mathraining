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
  
  # can_be_seen_by
  describe "can_be_seen_by should work" do
    let!(:contest) { FactoryBot.create(:contest, status: :in_progress) }
    let!(:contestproblem_not_started) { FactoryBot.create(:contestproblem, contest: contest, status: :not_started_yet) }
    let!(:contestproblem_in_progress) { FactoryBot.create(:contestproblem, contest: contest, status: :in_progress) }
    let!(:contestproblem_in_correction) { FactoryBot.create(:contestproblem, contest: contest, status: :in_correction) }
    let!(:contestproblem_corrected) { FactoryBot.create(:contestproblem, contest: contest, status: :corrected) }
    let!(:user1) { FactoryBot.create(:advanced_user) }
    let!(:user2) { FactoryBot.create(:advanced_user) }
    let!(:organizer) { FactoryBot.create(:advanced_user) }
    let!(:root) { FactoryBot.create(:root) }
    let!(:officialsolution_not_started) { contestproblem_not_started.contestsolutions.where(:official => true).first }
    let!(:contestsolution1_in_progress) { FactoryBot.create(:contestsolution, contestproblem: contestproblem_in_progress, user: user1, corrected: false, score: -1) }
    let!(:contestsolution2_in_progress) { FactoryBot.create(:contestsolution, contestproblem: contestproblem_in_progress, user: user2, corrected: false, score: -1) }
    let!(:officialsolution_in_progress) { contestproblem_in_progress.contestsolutions.where(:official => true).first }
    let!(:contestsolution1_in_correction) { FactoryBot.create(:contestsolution, contestproblem: contestproblem_in_correction, user: user1, corrected: true, score: 7) }
    let!(:contestsolution2_in_correction) { FactoryBot.create(:contestsolution, contestproblem: contestproblem_in_correction, user: user2, corrected: false, score: 3) }
    let!(:officialsolution_in_correction) { contestproblem_in_correction.contestsolutions.where(:official => true).first }
    let!(:contestsolution1_corrected) { FactoryBot.create(:contestsolution, contestproblem: contestproblem_corrected, user: user1, corrected: true, score: 7) }
    let!(:contestsolution2_corrected) { FactoryBot.create(:contestsolution, contestproblem: contestproblem_corrected, user: user2, corrected: true, score: 3) }
    let!(:officialsolution_corrected) { contestproblem_corrected.contestsolutions.where(:official => true).first }
    
    before do
      contest.organizers << organizer
      officialsolution_in_correction.update(corrected: true, score: 7)
      officialsolution_corrected.update(corrected: true, score: 0) # Not public
    end
    
    specify do
      expect(officialsolution_not_started.can_be_seen_by(user1)).to eq(false)
      expect(contestsolution1_in_progress.can_be_seen_by(user1)).to eq(false) # Can only see it through draft page
      expect(contestsolution2_in_progress.can_be_seen_by(user1)).to eq(false)
      expect(officialsolution_in_progress.can_be_seen_by(user1)).to eq(false)
      expect(contestsolution1_in_correction.can_be_seen_by(user1)).to eq(true)
      expect(contestsolution2_in_correction.can_be_seen_by(user1)).to eq(false)
      expect(officialsolution_in_correction.can_be_seen_by(user1)).to eq(false)
      expect(contestsolution1_corrected.can_be_seen_by(user1)).to eq(true)
      expect(contestsolution2_corrected.can_be_seen_by(user1)).to eq(false)
      expect(officialsolution_corrected.can_be_seen_by(user1)).to eq(false)
      
      expect(officialsolution_not_started.can_be_seen_by(user2)).to eq(false)
      expect(contestsolution1_in_progress.can_be_seen_by(user2)).to eq(false)
      expect(contestsolution2_in_progress.can_be_seen_by(user2)).to eq(false) # Can only see it through draft page
      expect(officialsolution_in_progress.can_be_seen_by(user2)).to eq(false)
      expect(contestsolution1_in_correction.can_be_seen_by(user2)).to eq(false)
      expect(contestsolution2_in_correction.can_be_seen_by(user2)).to eq(true)
      expect(officialsolution_in_correction.can_be_seen_by(user2)).to eq(false)
      expect(contestsolution1_corrected.can_be_seen_by(user2)).to eq(true) # Because it has score 7
      expect(contestsolution2_corrected.can_be_seen_by(user2)).to eq(true)
      expect(officialsolution_corrected.can_be_seen_by(user2)).to eq(false)
      
      expect(officialsolution_not_started.can_be_seen_by(organizer)).to eq(true)
      expect(contestsolution1_in_progress.can_be_seen_by(organizer)).to eq(false)
      expect(contestsolution2_in_progress.can_be_seen_by(organizer)).to eq(false)
      expect(officialsolution_in_progress.can_be_seen_by(organizer)).to eq(true)
      expect(contestsolution1_in_correction.can_be_seen_by(organizer)).to eq(true)
      expect(contestsolution2_in_correction.can_be_seen_by(organizer)).to eq(true)
      expect(officialsolution_in_correction.can_be_seen_by(organizer)).to eq(true)
      expect(contestsolution1_corrected.can_be_seen_by(organizer)).to eq(true)
      expect(contestsolution2_corrected.can_be_seen_by(organizer)).to eq(true)
      expect(officialsolution_corrected.can_be_seen_by(organizer)).to eq(true)
      
      expect(officialsolution_not_started.can_be_seen_by(root)).to eq(true)
      expect(contestsolution1_in_progress.can_be_seen_by(root)).to eq(true)
      expect(contestsolution2_in_progress.can_be_seen_by(root)).to eq(true)
      expect(officialsolution_in_progress.can_be_seen_by(root)).to eq(true)
      expect(contestsolution1_in_correction.can_be_seen_by(root)).to eq(true)
      expect(contestsolution2_in_correction.can_be_seen_by(root)).to eq(true)
      expect(officialsolution_in_correction.can_be_seen_by(root)).to eq(true)
      expect(contestsolution1_corrected.can_be_seen_by(root)).to eq(true)
      expect(contestsolution2_corrected.can_be_seen_by(root)).to eq(true)
      expect(officialsolution_corrected.can_be_seen_by(root)).to eq(true)
    end
  end
end
