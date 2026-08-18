# == Schema Information
#
# Table name: countries
#
#  id                  :integer          not null, primary key
#  code                :string
#  name                :string
#  name_without_accent :string
#
# Indexes
#
#  index_countries_on_name                 (name) UNIQUE
#  index_countries_on_name_without_accent  (name_without_accent)
#
require "spec_helper"

describe Country, country: true do
  let!(:country) { FactoryBot.build(:country, name: "Pépé", code: "pp") }

  subject { country }
  
  it { should be_valid }

  # Name
  describe "when name is not present" do
    before { country.name = nil }
    it { should_not be_valid }
  end
  
  describe "when name is already taken" do
    before { FactoryBot.create(:country, name: "Pépé", code: "qq") }
    it { should_not be_valid }
  end
  
  # Code
  describe "when code is not present" do
    before { country.code = nil }
    it { should_not be_valid }
  end
end
