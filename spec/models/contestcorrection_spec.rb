# == Schema Information
#
# Table name: contestcorrections
#
#  id                 :integer          not null, primary key
#  contestsolution_id :integer
#  content            :text
#
require "spec_helper"

describe Contestcorrection, contestcorrection: true do
  let!(:contestsolution) { FactoryBot.create(:contestsolution) } # Creates the contestcorrection automatically
  let!(:contestcorrection) { contestsolution.contestcorrection }

  subject { contestcorrection }

  it { should_not be_valid } # Because empty content is allowed at creation but not at update!

  # Content
  describe "when content is not present" do
    before { contestcorrection.content = nil }
    it { should_not be_valid }
  end
  
  describe "when content is added" do
    before { contestcorrection.content = "Voici" }
    it { should be_valid }
  end
  
  describe "when content is too long" do
    before { contestcorrection.content = "a" * 16001 }
    it { should_not be_valid }
  end
  
  # Uniqueness
  describe "when already present" do
    let!(:contestsolution2) { FactoryBot.create(:contestsolution) }
    before { contestcorrection.contestsolution = contestsolution2 }
    it { should_not be_valid }
  end
end
