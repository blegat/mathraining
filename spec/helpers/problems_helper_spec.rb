require "spec_helper"

describe ProblemsHelper, type: :helper, problem: true do

  include ChaptersHelper
  include ProblemsHelper
  
  let(:user_bad) { FactoryBot.create(:user, rating: 150) }
  let(:user) { FactoryBot.create(:user, rating: 200) }
  let(:user1) { FactoryBot.create(:user, rating: 200) }
  let(:user2) { FactoryBot.create(:user, rating: 200) }
  let(:user12) { FactoryBot.create(:user, rating: 200) }
  let(:user12_virtualtest) { FactoryBot.create(:user, rating: 400) }
  let(:admin) { FactoryBot.create(:admin) }
  let(:section) { FactoryBot.create(:section) }
  let!(:chapter1) { FactoryBot.create(:chapter, section: section, online: true) }
  let!(:chapter2) { FactoryBot.create(:chapter, section: section, online: true) }
  let!(:problem_no_prerequisite) { FactoryBot.create(:problem, section: section, online: true, level: 1, position: 1) } # Should not happen in production but we still want to support such problems
  let!(:problem1) { FactoryBot.create(:problem, section: section, online: true, level: 1, position: 2) }
  let!(:problem2) { FactoryBot.create(:problem, section: section, online: true, level: 1, position: 3) }
  let!(:problem12) { FactoryBot.create(:problem, section: section, online: true, level: 2, position: 1) }
  let!(:problem_offline) { FactoryBot.create(:problem, section: section, online: false, level: 2, position: 2) }
  let!(:problem1_other_section) { FactoryBot.create(:problem, online: true, level: 1, position: 1) }
  let!(:virtualtest) { FactoryBot.create(:virtualtest, online: true) }
  let!(:problem1_virtualtest) { FactoryBot.create(:problem, section: section, virtualtest: virtualtest, online: true, level: 3, position: 1) }
  
  before do
    user1.chapters << chapter1
    user2.chapters << chapter2
    user12.chapters << chapter1
    user12.chapters << chapter2
    user12_virtualtest.chapters << chapter1
    user12_virtualtest.chapters << chapter2
    problem1.chapters << chapter1
    problem2.chapters << chapter2
    problem12.chapters << chapter1
    problem12.chapters << chapter2
    problem1_other_section.chapters << chapter1
    Takentest.create(:virtualtest => virtualtest, :user => user12, :status => :in_progress)
    Takentest.create(:virtualtest => virtualtest, :user => user12_virtualtest, :status => :finished)
  end

  describe "non-accessible problems" do      
    it do
      expect(non_accessible_problems_ids(admin)).to eq(Set.new)
      expect(non_accessible_problems_ids(user12_virtualtest)).to eq(Set[problem_offline.id])
      expect(non_accessible_problems_ids(user12)).to eq(Set[problem_offline.id, problem1_virtualtest.id])
      expect(non_accessible_problems_ids(user1)).to eq(Set[problem_offline.id, problem2.id, problem12.id, problem1_virtualtest.id])
      expect(non_accessible_problems_ids(user2)).to eq(Set[problem_offline.id, problem1.id, problem12.id, problem1_other_section.id, problem1_virtualtest.id])
      expect(non_accessible_problems_ids(user)).to eq(Set[problem_offline.id, problem1.id, problem2.id, problem12.id, problem1_other_section.id, problem1_virtualtest.id])
      expect(non_accessible_problems_ids(user_bad)).to eq("all")
      expect(non_accessible_problems_ids(nil)).to eq("all") # not signed in
    end
  end
  
  describe "non-accessible problems from section" do
    it do      
      expect(non_accessible_problems_ids(admin, section)).to eq(Set.new)
      expect(non_accessible_problems_ids(user12_virtualtest, section)).to eq(Set[problem_offline.id])
      expect(non_accessible_problems_ids(user12, section)).to eq(Set[problem_offline.id, problem1_virtualtest.id])
      expect(non_accessible_problems_ids(user1, section)).to eq(Set[problem_offline.id, problem2.id, problem12.id, problem1_virtualtest.id])
      expect(non_accessible_problems_ids(user2, section)).to eq(Set[problem_offline.id, problem1.id, problem12.id, problem1_virtualtest.id])
      expect(non_accessible_problems_ids(user, section)).to eq(Set[problem_offline.id, problem1.id, problem2.id, problem12.id, problem1_virtualtest.id])
      expect(non_accessible_problems_ids(user_bad, section)).to eq("all")
      expect(non_accessible_problems_ids(nil, section)).to eq("all") # not signed in
    end
  end
  
  describe "accessible problems from section" do
    it do
      expect(accessible_problems_from_section(admin, section, ["id"]).map(&:id)).to eq([problem_no_prerequisite.id, problem1.id, problem2.id, problem12.id, problem_offline.id, problem1_virtualtest.id])
      expect(accessible_problems_from_section(user12_virtualtest, section, ["id"]).map(&:id)).to eq([problem_no_prerequisite.id, problem1.id, problem2.id, problem12.id, problem1_virtualtest.id])
      expect(accessible_problems_from_section(user12, section, ["id"]).map(&:id)).to eq([problem_no_prerequisite.id, problem1.id, problem2.id, problem12.id])
      expect(accessible_problems_from_section(user1, section, ["id"]).map(&:id)).to eq([problem_no_prerequisite.id, problem1.id])
      expect(accessible_problems_from_section(user2, section, ["id"]).map(&:id)).to eq([problem_no_prerequisite.id, problem2.id])
      expect(accessible_problems_from_section(user, section, ["id"]).map(&:id)).to eq([problem_no_prerequisite.id])
      expect(accessible_problems_from_section(user_bad, section, ["id"]).map(&:id)).to eq([])
      expect(accessible_problems_from_section(nil, section, ["id"]).map(&:id)).to eq([]) # not signed in
    end
  end
end
