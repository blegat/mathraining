# == Schema Information
#
# Table name: actualities
#
#  id         :integer          not null, primary key
#  title      :string
#  content    :text
#  created_at :datetime         not null
#
require "spec_helper"

describe Actuality, actuality: true do
  let!(:actuality) { FactoryBot.create(:actuality) }

  subject { actuality }
  
  it { should be_valid }

  # Title
  describe "when title is not present" do
    before { actuality.title = "" }
    it { should_not be_valid }
  end
  
  describe "when title is too long" do
    before { actuality.title = "a" * 256 }
    it { should_not be_valid }
  end

  # Content
  describe "when content is not present" do
    before { actuality.content = "" }
    it { should_not be_valid }
  end
  
  describe "when content is too long" do
    before { actuality.content = "HelloWorld" * 2000 }
    it { should_not be_valid }
  end

end
