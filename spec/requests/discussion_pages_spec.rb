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
  
  let(:attachments_folder) { "./spec/attachments/" }
  let(:image1) { "mathraining.png" } # default image used in factory
  let(:image2) { "Smiley1.gif" }
  let(:exe_attachment) { "hack.exe" }
  
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
    
    describe "wants to a send a message to a new guy" do
      before do
        visit user_path(other_user)
        click_link "Envoyer un message"
      end
      it do
        should have_current_path(new_discussion_path(:qui => other_user))
        should have_select("destinataire", selected: other_user.name)
      end
    end
    
    describe "wants to a send a message to a guy with a discussion" do
      let!(:discussion) { create_discussion_between(user, other_user, content, content2) }
      before do
        visit user_path(other_user)
        click_link "Envoyer un message"
      end
      it { should have_current_path(discussion_path(discussion)) }
    end
    
    describe "tries to see another discussion" do
      before do
        d = create_discussion_between(other_user, other_user2, content, content2)
        visit discussion_path(d)
      end
      it { should have_content(error_access_refused) }
    end
    
    describe "asks to receive emails for new messages" do
      before do
        visit new_discussion_path
        click_link "M'avertir des nouveaux messages par e-mail"
        user.reload
      end
      specify do
        expect(page).to have_success_message("Vous recevrez dorénavant un e-mail à chaque nouveau message privé.")
        expect(page).to have_link("Ne plus m'avertir par e-mail")
        expect(user.follow_message).to eq(true)
      end
      
      describe "and asks to not receive them anymore" do
        before do
          click_link "Ne plus m'avertir par e-mail"
          user.reload
        end
        specify do
          expect(page).to have_success_message("Vous ne recevrez maintenant plus d'e-mail lors d'un nouveau message privé.")
          expect(page).to have_link("M'avertir des nouveaux messages par e-mail")
          expect(user.follow_message).to eq(false)
        end
      end
    end
  end
  
  # -- TESTS THAT REQUIRE JAVASCRIPT --
  
  describe "user", :js => true do
    before { sign_in user }
    
    describe "sends a tchatmessage with a file" do
      let(:discussion) { create_discussion_between(user, other_user, content, content2) }
      before do
        visit discussion_path(discussion)
        fill_in "MathInput", with: content3
        click_button "Ajouter une pièce jointe"
        wait_for_ajax
        attach_file("file_1", File.absolute_path(attachments_folder + image2))
        click_button "Envoyer"
      end
      let(:newtchatmessage) { discussion.tchatmessages.order(:id).last }
      specify do
        expect(newtchatmessage.content).to eq(content3)
        expect(newtchatmessage.myfiles.count).to eq(1)
        expect(newtchatmessage.myfiles.first.file.filename.to_s).to eq(image2)
      end
    end
  end
end
