# == Schema Information
#
# Table name: solvedquestions
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  question_id     :integer
#  nb_guess        :integer
#  resolution_time :datetime
#
require "spec_helper"

describe Solvedquestion, solvedquestion: true do

  let(:sq) { FactoryBot.build(:solvedquestion) }

  subject { sq }

  it { should be_valid }

  # Number of guesses
  describe "when nb_guess is not present" do
    before { sq.nb_guess = nil }
    it { should_not be_valid }
  end
  describe "when nb_guess is 0" do
    before { sq.nb_guess = 0 }
    it { should_not be_valid }
  end
  describe "when nb_guess is negative" do
    before { sq.nb_guess = -1 }
    it { should_not be_valid }
  end
  
  # Resolution time
  describe "when resolution_time is not present" do
    before { sq.resolution_time = nil }
    it { should_not be_valid }
  end
  
  # detect_suspicious_users
  describe "detect_suspicious_users" do
    let!(:yesterday) { Date.today.in_time_zone - 1.day + 10.hours }
    let!(:cheater) { FactoryBot.create(:user) }
    let!(:sq1)  { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday) }
    let!(:sq2)  { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 15.seconds) }
    let!(:sq3)  { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 40.seconds) }
    let!(:sq4)  { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 45.seconds) }
    let!(:sq5)  { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 1.minute) }
    let!(:sq6)  { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 2.minutes + 4.seconds) }
    let!(:sq7)  { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 5.minutes) }
    let!(:sq8)  { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 5.minutes + 10.seconds) }
    let!(:sq9)  { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 11.minutes) }
    let!(:sq10) { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 11.minutes + 40.seconds) }
    let!(:sq11) { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 12.minutes + 20.seconds) }
    let!(:sq12) { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 12.minutes + 30.seconds) }
    let!(:sq13) { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 12.minutes + 40.seconds) }
    let!(:sq14) { FactoryBot.create(:solvedquestion, user: cheater, resolution_time: yesterday + 12.minutes + 50.seconds) }
    
    describe "searches for suspicious users for the first time" do
      before do
        Subject.where(:subject_type => :corrector_alerts).destroy_all
        Solvedquestion.detect_suspicious_users
      end
      specify do
        expect(Subject.where(:subject_type => :corrector_alerts).count).to eq(1)
        expect(Subject.last.messages.count).to eq(1)
        expect(Subject.last.messages.last.user_id).to eq(0)
        expect(Subject.last.messages.last.content).to include(cheater.name)
        expect(Subject.last.messages.last.content).to include("a résolu 6 exercices en 3 minutes et 8 exercices en 10 minutes")
        expect(Subject.last.messages.last.content).to include("Il a résolu 10 exercices après moins d'une minute de réflexion, dont un en 5 secondes")
      end
      
      describe "and searches a second time" do
        before { Solvedquestion.detect_suspicious_users }
        specify do
          expect(Subject.where(:subject_type => :corrector_alerts).count).to eq(1)
          expect(Subject.last.messages.count).to eq(2)
          expect(Message.last.user_id).to eq (0)
          expect(Message.last.content).to include(cheater.name)
          expect(Message.last.content).to include("a résolu 6 exercices en 3 minutes et 8 exercices en 10 minutes")
          expect(Message.last.content).to include("Il a résolu 10 exercices après moins d'une minute de réflexion, dont un en 5 secondes")
        end
      end
    end
  end
end
