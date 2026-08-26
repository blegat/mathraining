# == Schema Information
#
# Table name: problems
#
#  id               :integer          not null, primary key
#  archiving_date   :date
#  explanation      :text             default("-")
#  first_solve_time :datetime
#  last_solve_time  :datetime
#  level            :integer
#  markscheme       :text             default("-")
#  nb_solves        :integer          default(0)
#  number           :integer          default(1)
#  origin           :string
#  position         :integer          default(0)
#  publication_date :date
#  reviewed         :boolean          default(FALSE)
#  statement        :text
#  status           :integer          default("waiting_publication")
#  section_id       :integer
#  virtualtest_id   :integer          default(0)
#
# Indexes
#
#  index_problems_on_number      (number) UNIQUE
#  index_problems_on_section_id  (section_id)
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
  
  # Number
  describe "when number is not present" do
    before { problem.number = nil }
    it { should_not be_valid }
  end
  
  describe "when number is too small" do
    before { problem.number = 0 }
    it { should_not be_valid }
  end
  
  describe "when number is not unique" do
    before { FactoryBot.create(:problem, number: problem.number) }
    it { should_not be_valid }
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
        problem.published!
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
        problem.waiting_publication!
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
      let!(:virtualtest) { FactoryBot.create(:virtualtest, status: :published) }
      let!(:submission_wrong_user5) { FactoryBot.create(:submission, problem: problem, user: user5, status: :wrong) }
      
      before do
        problem.update(:status => :published, :virtualtest => virtualtest)
        Takentest.create(user: user3, virtualtest: virtualtest, status: :in_progress, taken_time: DateTime.now - 2.minutes)
        Takentest.create(user: user4, virtualtest: virtualtest, status: :finished, taken_time: DateTime.now - 2.days)
        Takentest.create(user: user5, virtualtest: virtualtest, status: :finished, taken_time: DateTime.now - 2.days)
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
  
  # auto_publish
  describe "auto_publish" do
    let!(:today) { Date.today }
    let!(:section) { FactoryBot.create(:section) }
    let!(:problem_to_publish) { FactoryBot.create(:problem, section: section, status: :waiting_publication, publication_date: today) }
    let!(:problem_to_publish_tomorrow) { FactoryBot.create(:problem, section: section, status: :waiting_publication, publication_date: today + 1.day) }
    let!(:old_max_score) { section.max_score }
    
    before do
      Problem.auto_publish
      problem_to_publish.reload
      problem_to_publish_tomorrow.reload
      section.reload
    end
    
    specify do
      expect(problem_to_publish.published?).to eq(true)
      expect(problem_to_publish_tomorrow.waiting_publication?).to eq(true)
      expect(section.max_score).to eq(old_max_score + problem_to_publish.value)
    end
  end
  
  # auto_archive
  describe "auto_archive" do
    let!(:today) { Date.today }
    let!(:section) { FactoryBot.create(:section) }
    let!(:other_section) { FactoryBot.create(:section) }
    let!(:problem_to_archive) { FactoryBot.create(:problem, section: section, status: :published, archiving_date: today) }
    let!(:problem_to_archive_tomorrow) { FactoryBot.create(:problem, section: section, status: :published, archiving_date: today + 1.day) }
    let!(:old_rating) { 200 }
    let!(:user) { FactoryBot.create(:user, rating: old_rating) }
    let!(:solvedproblem) { FactoryBot.create(:solvedproblem, user: user, problem: problem_to_archive) }
    let!(:pps_section) { user.pointspersections.where(section: section).first }
    let!(:pps_other_section) { user.pointspersections.where(section: other_section).first }
    let!(:old_max_score) { section.max_score }
    let!(:other_user) { FactoryBot.create(:user, rating: old_rating) }
    let!(:other_pps_section) { other_user.pointspersections.where(section: section).first }
    
    before do
      pps_section.update_attribute(:points, old_rating)
      pps_other_section.update_attribute(:points, old_rating)
      other_pps_section.update_attribute(:points, old_rating)
      Problem.auto_archive
      problem_to_archive.reload
      problem_to_archive_tomorrow.reload
      section.reload
      other_section.reload
      user.reload
      other_user.reload
      pps_section.reload
      pps_other_section.reload
      other_pps_section.reload
    end
    
    specify do
      expect(problem_to_archive.archived?).to eq(true)
      expect(problem_to_archive_tomorrow.published?).to eq(true)
      expect(section.max_score).to eq(old_max_score - problem_to_archive.value)
      expect(user.rating).to eq(old_rating - problem_to_archive.value)
      expect(other_user.rating).to eq(old_rating)
      expect(pps_section.points).to eq(old_rating - problem_to_archive.value)
      expect(pps_other_section.points).to eq(old_rating)
      expect(other_pps_section.points).to eq(old_rating)
    end
  end
end
