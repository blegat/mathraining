# == Schema Information
#
# Table name: followings
#
#  id                 :integer          not null, primary key
#  kind               :integer          default(NULL)
#  read               :boolean
#  created_at         :datetime         not null
#  submission_id      :integer
#  submission_user_id :integer
#  user_id            :integer
#
# Indexes
#
#  index_followings_on_created_at                       (created_at)
#  index_followings_on_submission_id                    (submission_id)
#  index_followings_on_submission_user_id               (submission_user_id)
#  index_followings_on_user_id_and_kind                 (user_id,kind)
#  index_followings_on_user_id_and_kind_and_created_at  (user_id,kind,created_at)
#  index_followings_on_user_id_and_submission_id        (user_id,submission_id) UNIQUE
#
require "spec_helper"

describe Following, following: true do

  let!(:user) { FactoryBot.create(:user) }
  let!(:submission) { FactoryBot.create(:submission) }
  let!(:following) { FactoryBot.build(:following, user: user, submission: submission) }

  subject { following }

  it { should be_valid }

  # Uniqueness
  describe "when user and submission are already taken" do
    before { FactoryBot.create(:following, user: user, submission: submission) }
    it { should_not be_valid }
  end
  
  # Kind
  describe "when kind is not present" do
    before { following.kind = nil }
    it { should_not be_valid }
  end

end
