# == Schema Information
#
# Table name: subjects
#
#  id                   :integer          not null, primary key
#  title                :string
#  chapter_id           :integer
#  last_comment_time    :datetime
#  for_correctors       :boolean          default(FALSE)
#  important            :boolean          default(FALSE)
#  section_id           :integer
#  for_wepion           :boolean          default(FALSE)
#  category_id          :integer
#  question_id          :integer
#  contest_id           :integer
#  problem_id           :integer
#  last_comment_user_id :integer
#  subject_type         :integer          default("normal")
#
require "spec_helper"

describe Subject, subject: true do

  let!(:sub) { FactoryBot.build(:subject) }

  subject { sub }

  it { should be_valid }

  # Title
  describe "when title is not present" do
    before { sub.title = nil }
    it { should_not be_valid }
  end
  
  # Question
  describe "when question is already taken" do
    let!(:question) { FactoryBot.create(:question) }
    let!(:sub_question) { FactoryBot.create(:subject, question: question, chapter: question.chapter, section: question.chapter.section) }
    before { sub.question = question }
    it { should_not be_valid }
  end
  
  # Problem
  describe "when problem is already taken" do
    let!(:problem) { FactoryBot.create(:problem) }
    let!(:sub_problem) { FactoryBot.create(:subject, problem: problem, section: problem.section) }
    before { sub.problem = problem }
    it { should_not be_valid }
  end
  
  # Contest
  describe "when contest is already taken" do
    let!(:contest) { FactoryBot.create(:contest) }
    let!(:sub_contest) { FactoryBot.create(:subject, contest: contest) }
    before { sub.contest = contest }
    it { should_not be_valid }
  end
  
  # Last comment
  describe "last_comment_time and last_comment_user_id are correct after creation" do
    let!(:sub2) { FactoryBot.create(:subject) }
    let!(:message1) { FactoryBot.create(:message, subject: sub2, created_at: DateTime.now - 2.days) }
    specify do
      expect(sub2.last_comment_time).to be_within(1.second).of(message1.created_at)
      expect(sub2.last_comment_user).to eq(message1.user)
    end
    
    describe "and is still correct after message creation" do
      let!(:message2) { FactoryBot.create(:message, subject: sub2) }
      before { sub2.reload }
      specify do
        expect(sub2.last_comment_time).to be_within(1.second).of(message2.created_at)
        expect(sub2.last_comment_user).to eq(message2.user)
      end
      
      describe "and is still correct after message deletion" do
        before do
          message2.destroy
          sub2.reload
        end
        specify do
          expect(sub2.last_comment_time).to be_within(1.second).of(message1.created_at)
          expect(sub2.last_comment_user).to eq(message1.user)
        end
      end
    end
  end
  
  # Cannot be for correctors and for wepion
  describe "when for correctors and for wepion" do
    before do
      sub.for_correctors = true
      sub.for_wepion = true
    end
    it { should_not be_valid }
  end
  
  # can_be_seen_by
  describe "can_be_seen_by should work" do
    let!(:user) { FactoryBot.create(:user) }
    let!(:wepion_user) { FactoryBot.create(:user, wepion: true) }
    let!(:corrector) { FactoryBot.create(:corrector) }
    let!(:admin) { FactoryBot.create(:admin) }
    let!(:sub_normal) { FactoryBot.create(:subject) }
    let!(:sub_wepion) { FactoryBot.create(:subject, for_wepion: true) }
    let!(:sub_correctors) { FactoryBot.create(:subject, for_correctors: true) }
    
    specify do
      expect(sub_normal.can_be_seen_by(user)).to eq(true)
      expect(sub_normal.can_be_seen_by(wepion_user)).to eq(true)
      expect(sub_normal.can_be_seen_by(corrector)).to eq(true)
      expect(sub_normal.can_be_seen_by(admin)).to eq(true)
      
      expect(sub_wepion.can_be_seen_by(user)).to eq(false)
      expect(sub_wepion.can_be_seen_by(wepion_user)).to eq(true)
      expect(sub_wepion.can_be_seen_by(corrector)).to eq(false)
      expect(sub_wepion.can_be_seen_by(admin)).to eq(true)
      
      expect(sub_correctors.can_be_seen_by(user)).to eq(false)
      expect(sub_correctors.can_be_seen_by(wepion_user)).to eq(false)
      expect(sub_correctors.can_be_seen_by(corrector)).to eq(true)
      expect(sub_correctors.can_be_seen_by(admin)).to eq(true)
    end
  end
  
  # last_page
  describe "last_page is correct for 1 message" do
    let!(:sub2) { FactoryBot.create(:subject) }
    let!(:message) { FactoryBot.create(:message, subject: sub2) }
    specify { expect(sub2.last_page).to eq(1) }
  end
  
  describe "last_page is correct for 20 messages" do
    let!(:sub2) { FactoryBot.create(:subject) }
     before do
      (1..20).each do |i|
        FactoryBot.create(:message, subject: sub2)
      end 
    end
    specify { expect(sub2.last_page).to eq(2) }
  end
  
  # page_with_message_num
  describe "page_with_message_num gives correct result" do
    specify do
      expect(Subject.page_with_message_num(1)).to eq(1)
      expect(Subject.page_with_message_num(10)).to eq(1)
      expect(Subject.page_with_message_num(11)).to eq(2)
      expect(Subject.page_with_message_num(20)).to eq(2)
      expect(Subject.page_with_message_num(31)).to eq(4)
      expect(Subject.page_with_message_num(1672)).to eq(168)
    end
  end
end
