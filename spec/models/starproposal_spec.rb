# == Schema Information
#
# Table name: starproposals
#
#  id            :bigint           not null, primary key
#  submission_id :bigint
#  user_id       :bigint
#  reason        :string
#  answer        :string
#  status        :integer          default("waiting_treatment")
#  created_at    :datetime         not null
#
require "spec_helper"

describe Starproposal, starproposal: true do

  let!(:starproposal) { FactoryBot.build(:starproposal) }

  subject { starproposal }

  it { should be_valid }

  # Reason
  describe "when reason is not present" do
    before { starproposal.reason = "" }
    it { should_not be_valid }
  end
  describe "when reason is too long" do
    before { starproposal.reason = "A" * 2001 }
    it { should_not be_valid }
  end
  
  # Answer
  describe "when answer is too long" do
    before { starproposal.answer = "A" * 2001 }
    it { should_not be_valid }
  end
  
  # Color class and Status string
  describe "color class and status string" do
    describe "when waiting treatment" do
      before { starproposal.waiting_treatment! }
      specify do
        expect(starproposal.color_class).to eq("warning")
        expect(starproposal.status_string).to eq("En attente")
      end
    end
    
    describe "when accepted" do
      before { starproposal.accepted! }
      specify do
        expect(starproposal.color_class).to eq("success")
        expect(starproposal.status_string).to eq("Accepté")
      end
    end
    
    describe "when rejected" do
      before { starproposal.rejected! }
      specify do
        expect(starproposal.color_class).to eq("danger")
        expect(starproposal.status_string).to eq("Rejeté")
      end
    end
  end
end
