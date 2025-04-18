# == Schema Information
#
# Table name: fakefiles
#
#  id                 :integer          not null, primary key
#  fakefiletable_type :string
#  fakefiletable_id   :integer
#  filename           :string
#  content_type       :string
#  byte_size          :integer
#  created_at         :datetime
#
require "spec_helper"

describe Fakefile, fakefile: true do
  let!(:sub) { FactoryBot.create(:subject) }
  let!(:fakefile) { Fakefile.new(:fakefiletable => sub, :filename => "coucou.png", :content_type => "image/png", :byte_size => "32") }

  subject { fakefile }
  
  it { should be_valid }

  # Associated object
  describe "when fakefiletable is not present" do
    before { fakefile.fakefiletable = nil }
    it { should_not be_valid }
  end
  
  # Filename
  describe "when filename is not present" do
    before { fakefile.filename = nil }
    it { should_not be_valid }
  end
  
  # content_type
  describe "when content_type is not present" do
    before { fakefile.content_type = nil }
    it { should_not be_valid }
  end
  
  # byte_size
  describe "when byte_size is not present" do
    before { fakefile.fakefiletable = nil }
    it { should_not be_valid }
  end
end
