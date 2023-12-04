# == Schema Information
#
# Table name: countries
#
#  id                  :integer          not null, primary key
#  name                :string
#  code                :string
#  name_without_accent :string
#
require "spec_helper"

describe Country, country: true do
  let!(:country) { FactoryGirl.build(:country, name: "Pépé", code: "pp") }

  subject { country }
  
  it { should be_valid }

  # Name
  describe "when name is not present" do
    before { country.name = nil }
    it { should_not be_valid }
  end
  
  describe "when name is already taken" do
    before { FactoryGirl.create(:country, name: "Pépé", code: "qq") }
    it { should_not be_valid }
  end
  
  # Code
  describe "when code is not present" do
    before { country.code = nil }
    it { should_not be_valid }
  end
  
  # Name without accent
  describe "name without accent should be created automatically" do
    before do
      country.save
      country.reload
    end
    specify do
      expect(country.name_without_accent).to eq("Pepe")
    end
  end

end
