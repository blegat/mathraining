# == Schema Information
#
# Table name: correctorapplications
#
#  id              :bigint           not null, primary key
#  content         :text
#  processed       :boolean          default(FALSE)
#  created_at      :datetime         not null
#  tchatmessage_id :bigint
#  user_id         :bigint
#
# Indexes
#
#  index_correctorapplications_on_tchatmessage_id  (tchatmessage_id)
#  index_correctorapplications_on_user_id          (user_id)
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
