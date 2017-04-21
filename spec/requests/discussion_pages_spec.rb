# -*- coding: utf-8 -*-
require "spec_helper"

describe "Discussion pages" do

  subject { page }
  
  let(:user) { FactoryGirl.create(:user) }
  let!(:other_user) { FactoryGirl.create(:user) }
  let(:content) { "Salut mon ami!" }
  let(:content2) { "Salut mon pote!" }
  let(:content3) { "Comment vas-tu?" }
  
  describe "user" do
    before { sign_in user }
    describe "creates a discussion" do
      before { create_discussion(other_user, content) }
      it { should have_selector("h3", text: other_user.name) }
      it { should have_selector("div", text: content) }
    end
    
    describe "answers to a discussion" do
      before do
        d = create_discussion_between(user, other_user, content, content2)
        visit discussion_path(d)
        answer_discussion(content3)
      end
      it { should have_selector("div", text: content3) }
      
      describe "creates a discussion that already existed" do
        before { create_discussion(other_user, content3) }
        it { should have_selector("div", text: content2) }
        it { should have_selector("div", text: content3) }
      end
    end
  end
	
end
