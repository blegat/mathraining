# -*- coding: utf-8 -*-
require "spec_helper"

describe "Discussion pages" do

  subject { page }
  
  let(:user) { FactoryGirl.create(:user) }
  let!(:other_user) { FactoryGirl.create(:user, last_connexion: DateTime.now) } # last_connexion to be sure that other_user appears in the list
  let!(:other_user2) { FactoryGirl.create(:user) }
  let(:content) { "Salut mon ami!" }
  let(:content2) { "Salut mon pote!" }
  let(:content3) { "Comment vas-tu?" }
  
  describe "visitor" do
    describe "tries to create a discussion" do
      before { visit new_discussion_path }
      it { should have_content(error_must_be_connected) }
    end
  end
  
  describe "user" do
    before { sign_in user }
    
    describe "visits new discussion page" do
      before { visit new_discussion_path }
      it { should have_selector("h3", text: "Nouvelle discussion") }
    
      describe "creates a discussion" do
        before do
          select other_user.name, from: "destinataire"
          fill_in "MathInput", with: content
          click_button "Envoyer"
        end
        it do
          should have_selector("h3", text: other_user.name)
          should have_selector("div", text: content)
        end
        
        describe "and creates again the same discussion" do
          before do
            visit new_discussion_path
            select other_user.name, from: "destinataire"
            fill_in "MathInput", with: content2
            click_button "Envoyer"
          end
          it do
            should have_selector("div", text: content)
            should have_selector("div", text: content2)
          end
        end
      end
    end
    
    describe "answers to a discussion" do
      before do
        d = create_discussion_between(user, other_user, content, content2)
        visit discussion_path(d)
        fill_in "MathInput", with: content3
        click_button "Envoyer"
      end
      it { should have_selector("div", text: content3) }
    end
    
    describe "tries to see another discussion" do
      before do
        d = create_discussion_between(other_user, other_user2, content, content2)
        visit discussion_path(d)
      end
      it { should have_content(error_access_refused) }
    end
  end
end
