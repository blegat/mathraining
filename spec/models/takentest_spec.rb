# == Schema Information
#
# Table name: takentests
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  virtualtest_id :integer
#  taken_time     :datetime
#  status         :integer
#
require "spec_helper"

describe Takentest, virtualtest: true do
  let!(:virtualtest) { FactoryBot.create(:virtualtest) }
  let!(:user) { FactoryBot.create(:advanced_user) }
  let!(:takentest) { Takentest.new(user: user, virtualtest: virtualtest, status: :in_progress, taken_time: DateTime.now) }

  subject { takentest }

  it { should be_valid }
  
  # Uniqueness
  describe "when already present" do
    before { Takentest.create(user: user, virtualtest: virtualtest, status: :finished, taken_time: DateTime.now - 1.day) }
    it { should_not be_valid }
  end
  
  # Taken time
  describe "when taken_time is not present" do
    before { takentest.taken_time = nil }
    it { should_not be_valid }
  end
  
  # Status
  describe "when status is not present" do
    before { takentest.status = nil }
    it { should_not be_valid }
  end
end
