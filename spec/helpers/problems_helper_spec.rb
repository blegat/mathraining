require "spec_helper"

describe ProblemsHelper, type: :helper, problem: true do

  include ChaptersHelper
  include ProblemsHelper
  
  let(:user_bad) { FactoryGirl.create(:user, rating: 150) }
  let(:user) { FactoryGirl.create(:user, rating: 200) }
  let(:user1) { FactoryGirl.create(:user, rating: 200) }
  let(:user2) { FactoryGirl.create(:user, rating: 200) }
  let(:user12) { FactoryGirl.create(:user, rating: 200) }
  let(:user12_virtualtest) { FactoryGirl.create(:user, rating: 400) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:section) { FactoryGirl.create(:section) }
  let!(:chapter1) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:chapter2) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:problem1) { FactoryGirl.create(:problem, section: section, online: true, level: 1, position: 1) }
  let!(:problem2) { FactoryGirl.create(:problem, section: section, online: true, level: 1, position: 2) }
  let!(:problem12) { FactoryGirl.create(:problem, section: section, online: true, level: 2, position: 1) }
  let!(:problem_offline) { FactoryGirl.create(:problem, section: section, online: false, level: 2, position: 2) }
  let!(:problem1_other_section) { FactoryGirl.create(:problem, online: true, level: 1, position: 1) }
  let!(:virtualtest) { FactoryGirl.create(:virtualtest, online: true) }
  let!(:problem1_virtualtest) { FactoryGirl.create(:problem, section: section, virtualtest: virtualtest, online: true, level: 3, position: 1) }
  
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
  
  describe "accessible problems from section" do
    it do      
      expect(accessible_problems_from_section(admin, section, ["id"]).map(&:id)).to eq([problem1.id, problem2.id, problem12.id, problem_offline.id, problem1_virtualtest.id])
      expect(accessible_problems_from_section(user12_virtualtest, section, ["id"]).map(&:id)).to eq([problem1.id, problem2.id, problem12.id, problem1_virtualtest.id])
      expect(accessible_problems_from_section(user12, section, ["id"]).map(&:id)).to eq([problem1.id, problem2.id, problem12.id])
      expect(accessible_problems_from_section(user1, section, ["id"]).map(&:id)).to eq([problem1.id])
      expect(accessible_problems_from_section(user2, section, ["id"]).map(&:id)).to eq([problem2.id])
      expect(accessible_problems_from_section(user, section, ["id"]).map(&:id)).to eq([])
      expect(accessible_problems_from_section(user_bad, section, ["id"]).map(&:id)).to eq([])
      expect(accessible_problems_from_section(nil, section, ["id"]).map(&:id)).to eq([]) # not signed in
    end
  end
end
