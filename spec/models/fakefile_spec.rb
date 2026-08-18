# == Schema Information
#
# Table name: fakefiles
#
#  id                 :integer          not null, primary key
#  byte_size          :integer
#  content_type       :string
#  fakefiletable_type :string
#  filename           :string
#  created_at         :datetime
#  fakefiletable_id   :integer
#
# Indexes
#
#  index_fakefiles_on_byte_size                                (byte_size)
#  index_fakefiles_on_fakefiletable_type_and_fakefiletable_id  (fakefiletable_type,fakefiletable_id)
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
