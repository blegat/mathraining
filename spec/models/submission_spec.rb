# == Schema Information
#
# Table name: submissions
#
#  id                :integer          not null, primary key
#  problem_id        :integer
#  user_id           :integer
#  content           :text
#  created_at        :datetime         not null
#  status            :integer          default("waiting")
#  intest            :boolean          default(FALSE)
#  score             :integer          default(-1)
#  last_comment_time :datetime
#  star              :boolean          default(FALSE)
#
require "spec_helper"

describe Submission, submission: true do
  let!(:submission) { FactoryBot.build(:submission) }

  subject { submission }

  it { should be_valid }

  # Content
  describe "when content is not present" do
    before { submission.content = " " }
    it { should_not be_valid }
  end
  describe "when content is too long" do
    before { submission.content = "a" * 16001 }
    it { should_not be_valid }
  end

  # Last comment time
  describe "last_comment_time is correct after creation" do
    let!(:submission2) { FactoryBot.create(:submission, created_at: DateTime.now - 2.days) }
    specify { expect(submission2.last_comment_time).to be_within(1.second).of(submission2.created_at) }
    
    describe "and is still correct after correction creation" do
      let!(:correction) { FactoryBot.create(:correction, submission: submission2) }
      before { submission2.reload }
      specify { expect(submission2.last_comment_time).to be_within(1.second).of(correction.created_at) }
      
      describe "and is still correct after correction deletion" do
        before do
          correction.destroy
          submission2.reload
        end
        specify { expect(submission2.last_comment_time).to be_within(1.second).of(submission2.created_at) }
      end
    end
  end
  
  # icon
  describe "icon" do
    let!(:sub_star) { FactoryBot.create(:submission, status: :correct, star: true) }
    let!(:sub_correct) { FactoryBot.create(:submission, status: :correct) }
    let!(:sub_wrong) { FactoryBot.create(:submission, status: :wrong) }
    let!(:sub_wrong_to_read) { FactoryBot.create(:submission, status: :wrong_to_read) }
    let!(:sub_draft) { FactoryBot.create(:submission, status: :draft) }
    let!(:sub_waiting) { FactoryBot.create(:submission, status: :waiting) }
    let!(:sub_waiting_forever) { FactoryBot.create(:submission, status: :waiting_forever) }
    let!(:sub_plagiarized) { FactoryBot.create(:submission, status: :plagiarized) }
    let!(:sub_ai) { FactoryBot.create(:submission, status: :generated_with_ai) }
    let!(:sub_closed) { FactoryBot.create(:submission, status: :closed) }
    specify do
      expect(sub_star.icon).to eq(star_icon)
      expect(sub_correct.icon).to eq(v_icon)
      expect(sub_wrong.icon).to eq(x_icon)
      expect(sub_wrong_to_read.icon).to eq(x_icon)
      expect(sub_draft.icon).to eq(dash_icon)
      expect(sub_waiting.icon).to eq(dash_icon)
      expect(sub_waiting_forever.icon).to eq(dash_icon)
      expect(sub_plagiarized.icon).to eq(warning_icon)
      expect(sub_ai.icon).to eq(ai_icon)
      expect(sub_closed.icon).to eq(blocked_icon)
    end
  end
  
  # date_new_submission_allowed
  describe "date_new_submission_allowed is correct" do
    let!(:sub_plagiarized) { FactoryBot.create(:submission, status: :plagiarized) }
    let!(:sub_closed) { FactoryBot.create(:submission, status: :closed) }
    let!(:sub_wrong) { FactoryBot.create(:submission, status: :wrong) }
    specify do
      expect(sub_plagiarized.date_new_submission_allowed).to eq(sub_plagiarized.last_comment_time.in_time_zone.to_date + 6.months)
      expect(sub_closed.date_new_submission_allowed).to eq(sub_closed.last_comment_time.in_time_zone.to_date + 1.week)
      expect(sub_wrong.date_new_submission_allowed).to be < Date.today
    end
  end
  
  # has_recent_activity
  describe "has_recent_activity is correct" do
    let!(:sub_old) { FactoryBot.create(:submission, created_at: DateTime.now - 65.days) }
    let!(:sub_not_so_old) { FactoryBot.create(:submission, created_at: DateTime.now - 55.days) }
    specify do
      expect(sub_old.has_recent_activity).to eq(false)
      expect(sub_not_so_old.has_recent_activity).to eq(true)
    end
  end
  
  # set_waiting_status
  describe "set_waiting_status is correct" do
    let!(:user1) { FactoryBot.create(:advanced_user) }
    let!(:user2) { FactoryBot.create(:advanced_user) }
    let!(:sanction1) { FactoryBot.create(:sanction, user: user1, sanction_type: :not_corrected, start_time: DateTime.now - 1.month, duration: 14) }
    let!(:sanction2) { FactoryBot.create(:sanction, user: user2, sanction_type: :not_corrected, start_time: DateTime.now - 1.week, duration: 14) }
    let!(:submission1) { FactoryBot.create(:submission, user: user1, status: :draft) }
    let!(:submission2) { FactoryBot.create(:submission, user: user2, status: :draft) }
    before do
      submission1.set_waiting_status
      submission2.set_waiting_status
    end
    specify do
      expect(submission1.waiting?).to eq(true)
      expect(submission2.waiting_forever?).to eq(true)
    end
  end
  
  # can_be_seen_by
  describe "can_be_seen_by should work" do
    let!(:user_wrong) { FactoryBot.create(:advanced_user) }
    let!(:user_correct) { FactoryBot.create(:advanced_user) }
    let!(:user_correct2) { FactoryBot.create(:advanced_user) }
    let!(:corrector_wrong) { FactoryBot.create(:corrector) }
    let!(:corrector_correct) { FactoryBot.create(:corrector) }
    let!(:admin) { FactoryBot.create(:admin) }
    let!(:problem) { FactoryBot.create(:problem, online: true) }
    let!(:sub_user_wrong) { FactoryBot.create(:submission, problem: problem, user: user_wrong, status: :wrong_to_read) }
    let!(:sub_user_draft) { FactoryBot.create(:submission, problem: problem, user: user_wrong, status: :draft) }
    let!(:sub_user_correct) { FactoryBot.create(:submission, problem: problem, user: user_correct, status: :correct) }
    let!(:sub_user_correct2) { FactoryBot.create(:submission, problem: problem, user: user_correct2, status: :correct) }
    let!(:sub_corrector_wrong) { FactoryBot.create(:submission, problem: problem, user: corrector_wrong, status: :wrong) }
    let!(:sub_corrector_correct) { FactoryBot.create(:submission, problem: problem, user: corrector_correct, status: :correct) }
    let!(:sp1) { FactoryBot.create(:solvedproblem, problem: problem, user: user_correct, submission: sub_user_correct) }
    let!(:sp2) { FactoryBot.create(:solvedproblem, problem: problem, user: user_correct2, submission: sub_user_correct2) }
    let!(:sp3) { FactoryBot.create(:solvedproblem, problem: problem, user: corrector_correct, submission: sub_corrector_correct) }
    
    specify do
      expect(sub_user_wrong.can_be_seen_by(user_wrong)).to eq(true)
      expect(sub_user_wrong.can_be_seen_by(user_correct)).to eq(false)
      expect(sub_user_wrong.can_be_seen_by(user_correct2)).to eq(false)
      expect(sub_user_wrong.can_be_seen_by(corrector_wrong)).to eq(false)
      expect(sub_user_wrong.can_be_seen_by(corrector_correct)).to eq(true)
      expect(sub_user_wrong.can_be_seen_by(admin)).to eq(true)
      
      expect(sub_user_draft.can_be_seen_by(user_wrong)).to eq(false) # a draft cannot be "seen" by the owner of the draft!
      expect(sub_user_draft.can_be_seen_by(user_correct)).to eq(false)
      expect(sub_user_draft.can_be_seen_by(user_correct2)).to eq(false)
      expect(sub_user_draft.can_be_seen_by(corrector_wrong)).to eq(false)
      expect(sub_user_draft.can_be_seen_by(corrector_correct)).to eq(false)
      expect(sub_user_draft.can_be_seen_by(admin)).to eq(true)
      
      expect(sub_user_correct.can_be_seen_by(user_wrong)).to eq(false)
      expect(sub_user_correct.can_be_seen_by(user_correct)).to eq(true)
      expect(sub_user_correct.can_be_seen_by(user_correct2)).to eq(true)
      expect(sub_user_correct.can_be_seen_by(corrector_wrong)).to eq(false)
      expect(sub_user_correct.can_be_seen_by(corrector_correct)).to eq(true)
      expect(sub_user_correct.can_be_seen_by(admin)).to eq(true)
      
      expect(sub_user_wrong.can_be_corrected_by(corrector_wrong)).to eq(false)
      expect(sub_user_wrong.can_be_corrected_by(user_correct)).to eq(false)
      expect(sub_user_wrong.can_be_corrected_by(corrector_correct)).to eq(true)
      expect(sub_user_wrong.can_be_corrected_by(admin)).to eq(true)
      expect(sub_corrector_correct.can_be_corrected_by(corrector_correct)).to eq(false) # Cannot correct his own submission
    end
  end
  
  # mark_correct
  describe "mark_correct" do
    let!(:section) { FactoryBot.create(:section) }
    let!(:user) { FactoryBot.create(:advanced_user, rating: 623) }
    let!(:problem) { FactoryBot.create(:problem, section: section, level: 4) }
    let!(:submission_wrong) { FactoryBot.create(:submission, user: user, problem: problem, status: :wrong_to_read, created_at: DateTime.now - 3.days) }
    let!(:submission_draft) { FactoryBot.create(:submission, user: user, problem: problem, status: :draft) }
    before do
      submission_wrong.mark_correct
      user.reload
      problem.reload
    end
    specify do
      expect(submission_wrong.correct?).to eq(true)
      expect(user.submissions.where(:problem => problem, :status => :draft).count).to eq(0) # Draft should have been deleted
      expect(user.pb_solved?(problem)).to eq(true)
      expect(problem.nb_solves).to eq(1)
      expect(problem.first_solve_time).to be_within(1.second).of(submission_wrong.created_at)
      expect(problem.last_solve_time).to be_within(1.second).of(submission_wrong.created_at)
      expect(user.rating).to eq(623 + problem.value)
      expect(user.pointspersections.where(:section => section).first.points).to eq(problem.value)
      expect(user.solvedproblems.where(:problem => problem).first.submission).to eq(submission_wrong)
    end
    
    describe "and mark_incorrect" do
      before do
        submission_wrong.mark_incorrect
        user.reload
        problem.reload
      end
      specify do
        expect(submission_wrong.wrong?).to eq(true)
        expect(user.pb_solved?(problem)).to eq(false)
        expect(problem.nb_solves).to eq(0)
        expect(problem.first_solve_time).to eq(nil)
        expect(problem.last_solve_time).to eq(nil)
        expect(user.rating).to eq(623)
        expect(user.pointspersections.where(:section => section).first.points).to eq(0)
      end
    end
    
    describe "and mark_incorrect when there is another correct submission" do
      let!(:submission_correct) { FactoryBot.create(:submission, user: user, problem: problem, status: :correct, created_at: DateTime.now - 1.day) }
      let!(:correction) { FactoryBot.create(:correction, submission: submission_correct, created_at: DateTime.now - 2.hours) }
      before do
        submission_wrong.mark_incorrect
        user.reload
        problem.reload
      end
      specify do
        expect(submission_wrong.wrong?).to eq(true)
        expect(user.pb_solved?(problem)).to eq(true)
        expect(problem.nb_solves).to eq(1)
        expect(problem.first_solve_time).to be_within(1.second).of(submission_correct.created_at)
        expect(problem.last_solve_time).to be_within(1.second).of(submission_correct.created_at)
        expect(user.rating).to eq(623 + problem.value)
        expect(user.pointspersections.where(:section => section).first.points).to eq(problem.value)
        expect(user.solvedproblems.where(:problem => problem).first.submission).to eq(submission_correct) # submission_wrong should have been replaced by submission_correct
        expect(user.solvedproblems.where(:problem => problem).first.resolution_time).to be_within(1.second).of(submission_correct.created_at)
        expect(user.solvedproblems.where(:problem => problem).first.correction_time).to be_within(1.second).of(correction.created_at)
      end
    end
  end
end
