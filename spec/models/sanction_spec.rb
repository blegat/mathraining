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
  describe "when reason does not contain [DATE]" do
    before { sanction.reason = "Vous êtes banni" }
    it { should_not be_valid }
  end
  describe "when reason contains [DATE] twice." do
    before { sanction.reason = "Vous êtes banni du [DATE] au [DATE]." }
    it { should_not be_valid }
  end
end
