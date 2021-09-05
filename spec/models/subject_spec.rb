# == Schema Information
#
# Table name: subjects
#
#  id                  :integer          not null, primary key
#  title               :string
#  content             :text
#  user_id             :integer
#  chapter_id          :integer
#  created_at          :datetime
#  updated_at          :datetime
#  lastcomment         :datetime
#  admin               :boolean          default(FALSE)
#  important           :boolean          default(FALSE)
#  section_id          :integer
#  wepion              :boolean          default(FALSE)
#  category_id         :integer
#  question_id         :integer
#  contest_id          :integer
#  problem_id          :integer
#  lastcomment_user_id :integer
#
require "spec_helper"

describe Subject do

  before { @s = FactoryGirl.build(:subject) }

  subject { @s }

  it { should respond_to(:title) }
  it { should respond_to(:content) }
  it { should respond_to(:user) }
  it { should respond_to(:lastcomment) }
  it { should respond_to(:admin) }
  it { should respond_to(:important) }
  it { should respond_to(:wepion) }

  it { should be_valid }

  # Title
  describe "when title is not present" do
    before { @s.title = nil }
    it { should_not be_valid }
  end
  
  # Content
  describe "when content is not present" do
    before { @s.content = nil }
    it { should_not be_valid }
  end

  # User
  describe "when user is not present" do
    before { @s.user = nil }
    it { should_not be_valid }
  end


end
