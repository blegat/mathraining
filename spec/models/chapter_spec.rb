# == Schema Information
#
# Table name: chapters
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  level       :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'spec_helper'

describe User do

  before { @chap = Chapter.new(name: "Example",
                               description: "Nice example",
                               level: 0) }

  subject { @chap }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:level) }
  it { should respond_to(:available_prerequisites) }
  it { should respond_to(:recursive_prerequisites) }

  it { should be_valid }

  describe "when name is not present" do
    before { @chap.name = " " }
    it { should_not be_valid }
  end
  describe "when name is too long" do
    before { @chap.name = "a" * 256 }
    it { should_not be_valid }
  end
  describe "when name is already taken" do
    before do
      other_chap = Chapter.new(name: @chap.name,
                               description: "Other description",
                               level: (@chap.level + 1) % 10)
      other_chap.save
    end
    it { should_not be_valid }
  end

  describe "when description is not present" do
    before { @chap.description = nil }
    it { should be_valid }
  end
  describe "when description is too long" do
    before { @chap.description = "a" * 8001 }
    it { should_not be_valid }
  end

end
