# -*- coding: utf-8 -*-
require "spec_helper"

describe "Discussion pages" do

  subject { page }
  
  let(:user) { FactoryGirl.create(:user) }
  let!(:other_user) { FactoryGirl.create(:user) }
  let!(:other_user2) { FactoryGirl.create(:user) }
  let(:content) { "Salut mon ami!" }
  let(:content2) { "Salut mon pote!" }
   
  describe "visitor" do
    describe "visits discussion/index" do
      before { visit new_discussion_path }
      it { should_not have_selector("h1", text: "Messages") }
    end
  end
  
  describe "user" do
    before { sign_in user }
    describe "visits discussion/new" do
      before { visit new_discussion_path }
      it { should have_selector("h3", text: "Nouvelle discussion") }
    end
    
    describe "visits discussion/show" do
      before do
        d = create_discussion_between(user, other_user, content, content2)
        visit discussion_path(d)
      end
      it { should have_selector("h3", text: other_user.name) }
      it { should have_selector("div", text: content) }
    end
    
    describe "tries to see another discussion" do
      before do
        d = create_discussion_between(other_user, other_user2, content, content2)
        visit discussion_path(d)
      end
      it { should_not have_selector("div", text: content) }
    end
  end
	
end
