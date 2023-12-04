# == Schema Information
#
# Table name: discussions
#
#  id                :integer          not null, primary key
#  last_message_time :datetime
#
require "spec_helper"

describe Discussion, discussion: true do
  let!(:discussion) { Discussion.new }

  subject { discussion }
  
  it { should be_valid }
end
