# == Schema Information
#
# Table name: myfiles
#
#  id               :integer          not null, primary key
#  myfiletable_type :string
#  myfiletable_id   :integer
#
require "spec_helper"

describe Myfile, myfile: true do

  let(:myfile) { FactoryBot.build(:messagemyfile) }
  before { myfile.file.attach(io: File.open(Rails.root.join('spec', 'attachments', 'mathraining.png')), filename: 'mathraining.png', content_type: 'image/png') }

  subject { myfile }

  it { should be_valid }

  # is_image
  describe "is_image" do
    describe "for an image" do
      specify { expect(myfile.is_image).to eq(true) }
    end
    
    describe "for a text file" do
      before { myfile.file.attach(io: File.open(Rails.root.join('spec', 'attachments', 'test.txt')), filename: 'test.txt', content_type: 'text/plain') }
      specify { expect(myfile.is_image).to eq(false) }
    end
  end
  
  # fake_dels
  describe "fake_dels" do
    let!(:root) { FactoryBot.create(:root) }
    let!(:user) { FactoryBot.create(:user) }
    let!(:discussion) { create_discussion_between(root, user, "Bonjour", "Salut") }
    let!(:tchatmessage1) { discussion.tchatmessages.first }
    let!(:tchatmessage2) { discussion.tchatmessages.second }
    
    before do
      myfile11 = FactoryBot.create(:tchatmessagemyfile, myfiletable: tchatmessage1)
      myfile12 = FactoryBot.create(:tchatmessagemyfile, myfiletable: tchatmessage1)
      myfile21 = FactoryBot.create(:tchatmessagemyfile, myfiletable: tchatmessage2)
      myfile22 = FactoryBot.create(:tchatmessagemyfile, myfiletable: tchatmessage2)
      myfile11.file.blob.update_attribute(:created_at, DateTime.now - 50.days)
      myfile12.file.blob.update_attribute(:created_at, DateTime.now - 30.days)
      myfile21.file.blob.update_attribute(:created_at, DateTime.now - 26.days)
      myfile22.file.blob.update_attribute(:created_at, DateTime.now - 10.days)
      Myfile.fake_dels
      tchatmessage1.reload
      tchatmessage2.reload
    end
    specify do
      expect(tchatmessage1.myfiles.count).to eq(0)
      expect(tchatmessage1.fakefiles.count).to eq(2)
      expect(tchatmessage1.fakefiles.first.filename).to eq("mathraining.png") # default image for tests
      expect(tchatmessage1.fakefiles.second.filename).to eq("mathraining.png") # default image for tests
      expect(tchatmessage2.myfiles.count).to eq(2)
      expect(tchatmessage2.fakefiles.count).to eq(0)
    end
  end
end
