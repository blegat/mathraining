# == Schema Information
#
# Table name: problems
#
#  id               :integer          not null, primary key
#  statement        :text
#  online           :boolean          default(FALSE)
#  level            :integer
#  explanation      :text             default("-")
#  section_id       :integer
#  number           :integer          default(1)
#  virtualtest_id   :integer          default(0)
#  position         :integer          default(0)
#  origin           :string
#  markscheme       :text             default("-")
#  nb_solves        :integer          default(0)
#  first_solve_time :datetime
#  last_solve_time  :datetime
#  reviewed         :boolean
#
require "spec_helper"

describe Problem, problem: true do

  let!(:problem) { FactoryBot.build(:problem) }

  subject { problem }

  it { should be_valid }

  # Statement
  describe "when statement is not present" do
    before { problem.statement = nil }
    it { should_not be_valid }
  end
  
  describe "when statement is too long" do
    before { problem.statement = "a" * 16001 }
    it { should_not be_valid }
  end

  # Level
  describe "when level is not present" do
    before { problem.level = nil }
    it { should_not be_valid }
  end
  
  describe "when level is too small" do
    before { problem.level = 0 }
    it { should_not be_valid }
  end
  
  describe "when level is too large" do
    before { problem.level = 6 }
    it { should_not be_valid }
  end
  
  # Value
  describe "value" do
    before { problem.level = 3 }
    specify { expect(problem.value).to eq(problem.level * 15) }
  end
  
  # can_be_seen_by
  describe "can_be_updated_by should work" do
    let!(:user1) { FactoryBot.create(:user, rating: 200) }
    let!(:user2) { FactoryBot.create(:user, rating: 180) }
    let!(:user3) { FactoryBot.create(:user, rating: 200) }
    let!(:user4) { FactoryBot.create(:user, rating: 200) }
    let!(:user5) { FactoryBot.create(:user, rating: 200) }
    let!(:admin) { FactoryBot.create(:admin) }
    let!(:chapter) { FactoryBot.create(:chapter) }
    
    before { problem.save }
      
    describe "for a normal online problem" do
      let!(:submission_draft_user4) { FactoryBot.create(:submission, problem: problem, user: user4, status: :draft) }
      let!(:submission_wrong_user5) { FactoryBot.create(:submission, problem: problem, user: user5, status: :wrong) } 
       
      before do
        problem.update(:online => true)
        problem.chapters << chapter
        user2.chapters << chapter
        user3.chapters << chapter
        user4.chapters << chapter
        user5.chapters << chapter
      end
    
      specify do
        # General case
        expect(problem.can_be_seen_by(admin, false)).to eq(true)
        expect(problem.can_be_seen_by(user1, false)).to eq(false) # prerequisite not completed
        expect(problem.can_be_seen_by(user2, false)).to eq(false) # rating not high enough
        expect(problem.can_be_seen_by(user3, false)).to eq(true)  # prerequisite completed
        expect(problem.can_be_seen_by(user4, false)).to eq(true)  # prerequisite completed + draft submission
        expect(problem.can_be_seen_by(user5, false)).to eq(true)  # prerequisite completed + wrong submission
      
        # When no new submissions
        expect(problem.can_be_seen_by(admin, true)).to eq(true)
        expect(problem.can_be_seen_by(user1, true)).to eq(false)
        expect(problem.can_be_seen_by(user2, true)).to eq(false)
        expect(problem.can_be_seen_by(user3, true)).to eq(false) # Not shown because no submission
        expect(problem.can_be_seen_by(user4, true)).to eq(false) # Not shown because only draft submission
        expect(problem.can_be_seen_by(user5, true)).to eq(true)  # Shown thanks to the wrong submission
      end
    end
    
    describe "for a normal offline problem" do    
      before do
        problem.update(:online => false)
        problem.chapters << chapter
        user3.chapters << chapter
      end
    
      specify do
        # General case
        expect(problem.can_be_seen_by(admin, false)).to eq(true)
        expect(problem.can_be_seen_by(user1, false)).to eq(false)
        expect(problem.can_be_seen_by(user3, false)).to eq(false)
      
        # When no new submissions
        expect(problem.can_be_seen_by(admin, true)).to eq(true)
        expect(problem.can_be_seen_by(user1, true)).to eq(false)
        expect(problem.can_be_seen_by(user3, true)).to eq(false)
      end
    end
    
    describe "for a problem in a virtualtest" do
      let!(:virtualtest) { FactoryBot.create(:virtualtest, online: true) }
      let!(:submission_wrong_user5) { FactoryBot.create(:submission, problem: problem, user: user5, status: :wrong) }
      
      before do
        problem.update(:online => true, :virtualtest => virtualtest)
        Takentest.create(user: user3, virtualtest: virtualtest, status: :in_progress)
        Takentest.create(user: user4, virtualtest: virtualtest, status: :finished)
        Takentest.create(user: user5, virtualtest: virtualtest, status: :finished)
      end
      
      specify do
        # General case
        expect(problem.can_be_seen_by(admin, false)).to eq(true)
        expect(problem.can_be_seen_by(user1, false)).to eq(false) # Test not started
        expect(problem.can_be_seen_by(user3, false)).to eq(false) # Test in progress: don't show the problem in problem section
        expect(problem.can_be_seen_by(user4, false)).to eq(true)  # Test finished
        expect(problem.can_be_seen_by(user5, false)).to eq(true)  # Test finished
      
        # When no new submissions
        expect(problem.can_be_seen_by(admin, true)).to eq(true)
        expect(problem.can_be_seen_by(user1, true)).to eq(false)
        expect(problem.can_be_seen_by(user3, true)).to eq(false)
        expect(problem.can_be_seen_by(user4, true)).to eq(false) # Not shown because no submission
        expect(problem.can_be_seen_by(user5, true)).to eq(true)  # Shown thanks to the wrong submission
      end
    end
  end

end
