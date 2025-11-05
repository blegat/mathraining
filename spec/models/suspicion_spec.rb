# == Schema Information
#
# Table name: suspicions
#
#  id            :bigint           not null, primary key
#  submission_id :bigint
#  user_id       :bigint
#  source        :text
#  status        :integer          default("waiting_confirmation")
#  created_at    :datetime         not null
#
require "spec_helper"

describe Suspicion, suspicion: true do

  let!(:suspicion) { FactoryBot.build(:suspicion) }

  subject { suspicion }

  it { should be_valid }

  # Source
  describe "when source is not present" do
    before { suspicion.source = "" }
    it { should_not be_valid }
  end
  describe "when source is too long" do
    before { suspicion.source = "A" * 1001 }
    it { should_not be_valid }
  end
  
  # Color class and Status string
  describe "color class and status string" do
    describe "when waiting confirmation" do
      before { suspicion.waiting_confirmation! }
      specify do
        expect(suspicion.color_class).to eq("warning")
        expect(suspicion.status_string).to eq("À confirmer")
      end
    end
    
    describe "when confirmed" do
      before { suspicion.confirmed! }
      specify do
        expect(suspicion.color_class).to eq("success")
        expect(suspicion.status_string).to eq("Confirmé")
      end
    end
    
    describe "when forgiven" do
      before { suspicion.forgiven! }
      specify do
        expect(suspicion.color_class).to eq("danger")
        expect(suspicion.status_string).to eq("Pardonné")
      end
    end
    
    describe "when rejected" do
      before { suspicion.rejected! }
      specify do
        expect(suspicion.color_class).to eq("danger")
        expect(suspicion.status_string).to eq("Rejeté")
      end
    end
  end
end
