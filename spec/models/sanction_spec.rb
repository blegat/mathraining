# == Schema Information
#
# Table name: sanctions
#
#  id            :bigint           not null, primary key
#  user_id       :bigint
#  sanction_type :integer
#  start_time    :datetime
#  duration      :integer
#  reason        :text
#
require "spec_helper"

describe Sanction, sanction: true do

  let!(:sanction) { FactoryBot.build(:sanction) }

  subject { sanction }

  it { should be_valid }
  
  # Sanction type
  describe "when sanction_type is not present" do
    before { sanction.sanction_type = nil }
    it { should_not be_valid }
  end

  # Start time
  describe "when start_time is not present" do
    before { sanction.start_time = nil }
    it { should_not be_valid }
  end

  # Duration
  describe "when duration is not present" do
    before { sanction.duration = nil }
    it { should_not be_valid }
  end
  describe "when duration is zero" do
    before { sanction.duration = 0 }
    it { should_not be_valid }
  end

  # Reason
  describe "when reason is not present" do
    before { sanction.reason = nil }
    it { should_not be_valid }
  end
  
  # message
  describe "old messages are still correct" do
    before do
      sanction.start_time = DateTime.new(2025, 11, 15, 15, 0, 0)
      sanction.duration = 3
      sanction.reason = "Vous êtes puni jusqu'au [DATE]."
    end
    specify { expect(sanction.message).to eq("Vous êtes puni jusqu'au 18 novembre 2025.") }
  end
  describe "new messages for ban are correct" do
    before do
      sanction.start_time = DateTime.new(2025, 12, 15, 15, 0, 0)
      sanction.sanction_type = :ban
      sanction.duration = 3
      sanction.reason = "Vous n'avez pas été gentil."
    end
    specify { expect(sanction.message).to eq("Ce compte a été temporairement désactivé jusqu'au 18 décembre 2025. Vous n'avez pas été gentil.") }
  end
  describe "new messages for no submission are correct" do
    before do
      sanction.start_time = DateTime.new(2025, 12, 15, 15, 0, 0)
      sanction.sanction_type = :no_submission
      sanction.duration = 3
      sanction.reason = "Vous n'avez pas été gentil."
    end
    specify { expect(sanction.message).to eq("Il ne vous est plus possible de faire de nouvelles soumissions ou d'écrire de nouveaux commentaires jusqu'au 18 décembre 2025. Vous n'avez pas été gentil.") }
  end
end
