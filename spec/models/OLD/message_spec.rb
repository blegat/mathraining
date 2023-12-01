# == Schema Information
#
# Table name: messages
#
#  id         :integer          not null, primary key
#  content    :text
#  subject_id :integer
#  user_id    :integer
#  created_at :datetime         not null
#
require "spec_helper"

describe Message do

  before { @m = FactoryGirl.build(:message) }

  subject { @m }

  it { should respond_to(:content) }
  it { should respond_to(:subject) }
  it { should respond_to(:user) }

  it { should be_valid }

  # Content
  describe "when content is not present" do
    before { @m.content = nil }
    it { should_not be_valid }
  end

  # User
  describe "when user is not present" do
    before { @m.user = nil }
    it { should_not be_valid }
  end

  # Subject
  describe "when subject is not present" do
    before { @m.subject = nil }
    it { should_not be_valid }
  end

end
