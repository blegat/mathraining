# == Schema Information
#
# Table name: correctorapplications
#
#  id              :bigint           not null, primary key
#  user_id         :bigint
#  content         :text
#  processed       :boolean          default(FALSE)
#  tchatmessage_id :bigint
#  created_at      :datetime         not null
#
require "spec_helper"

describe Correctorapplication, correctorapplication: true do

  let!(:correctorapplication) { FactoryBot.build(:correctorapplication) }

  subject { correctorapplication }

  it { should be_valid }

  # Content
  describe "when content is not present" do
    before { correctorapplication.content = "" }
    it { should_not be_valid }
  end
  describe "when content is too long" do
    before { correctorapplication.content = "A" * 16001 }
    it { should_not be_valid }
  end
end
