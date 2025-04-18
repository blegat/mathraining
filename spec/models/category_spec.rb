# == Schema Information
#
# Table name: categories
#
#  id   :integer          not null, primary key
#  name :string
#
require "spec_helper"

describe Category, category: true do
  let!(:category) { FactoryBot.create(:category) }

  subject { category }
  
  it { should be_valid }

  # Name
  describe "when name is not present" do
    before { category.name = "" }
    it { should_not be_valid }
  end
  
  describe "when name is too long" do
    before { category.name = "a" * 256 }
    it { should_not be_valid }
  end

end
