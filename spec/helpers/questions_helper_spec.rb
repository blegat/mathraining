require "spec_helper"

describe QuestionsHelper, type: :helper, question: true do

  include QuestionsHelper
  
  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:admin) { FactoryBot.create(:admin) }
  let!(:question1) { FactoryBot.create(:question, online: true) }
  let!(:question2) { FactoryBot.create(:question, online: true) }
  let!(:solvedquestion1) { FactoryBot.create(:solvedquestion, question: question1, user: user1) }
  
  describe "fully accessible questions" do
    it do
      expect(fully_accessible_questions_ids(admin)).to eq("all")
      expect(fully_accessible_questions_ids(user1)).to eq(Set[question1.id])
      expect(fully_accessible_questions_ids(user2)).to eq(Set.new)
      expect(fully_accessible_questions_ids(nil)).to eq(Set.new) # not signed in
    end
  end
end
