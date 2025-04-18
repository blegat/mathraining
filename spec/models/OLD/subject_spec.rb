# == Schema Information
#
# Table name: subjects
#
#  id                   :integer          not null, primary key
#  title                :string
#  chapter_id           :integer
#  last_comment_time    :datetime
#  for_correctors       :boolean          default(FALSE)
#  important            :boolean          default(FALSE)
#  section_id           :integer
#  for_wepion           :boolean          default(FALSE)
#  category_id          :integer
#  question_id          :integer
#  contest_id           :integer
#  problem_id           :integer
#  last_comment_user_id :integer
#  subject_type         :integer          default("normal")
#
require "spec_helper"

describe Subject do

  before { @s = FactoryBot.build(:subject) }

  subject { @s }

  it { should respond_to(:title) }
  it { should respond_to(:last_comment_time) }
  it { should respond_to(:for_correctors) }
  it { should respond_to(:important) }
  it { should respond_to(:for_wepion) }

  it { should be_valid }

  # Title
  describe "when title is not present" do
    before { @s.title = nil }
    it { should_not be_valid }
  end
end
