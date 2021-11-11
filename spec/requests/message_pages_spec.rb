# -*- coding: utf-8 -*-
require "spec_helper"

describe "Message pages" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:other_admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }

  let!(:sub) { FactoryGirl.create(:subject) }
  let!(:sub2) { FactoryGirl.create(:subject) }

  let!(:mes) { FactoryGirl.create(:message, subject: sub) }
  let!(:mes_user) { FactoryGirl.create(:message, user: user, subject: sub) }
  let!(:mes_admin) { FactoryGirl.create(:message, user: admin, subject: sub) }
  let!(:mes_other_admin) { FactoryGirl.create(:message, user: other_admin, subject: sub) }
  let!(:mes_other_root) { FactoryGirl.create(:message, user: other_root, subject: sub2) }
  
  let(:content) { "Ma belle réponse" }
  let(:content2) { "Ma nouvelle réponse" }
  
  describe "visitor" do 
    describe "tries to create a message" do
      before { visit subject_path(sub) }
      it { should have_content(error_must_be_connected) }
    end
  end
  
  describe "user" do
    before { sign_in user }
    
    describe "visits a subject" do
      before { visit subject_path(sub) }
      it do
        should have_link("LinkEditMessage#{mes_user.id}")
        should have_no_link("LinkDeleteMessage#{mes_user.id}")
        should have_button("SubmitMessage#{mes_user.id}")
        should have_no_link("LinkEditMessage#{mes.id}")
        should have_no_button("SubmitMessage#{mes.id}")
        should have_button("Répondre")
        should have_button("Poster")
      end
      
      describe "and edits his message" do
        before do
          fill_in "MathInputMessage#{mes_user.id}", with: content
          click_button "SubmitMessage#{mes_user.id}"
          mes_user.reload
        end
        it { should have_content("Votre message a bien été modifié.") }
        specify { expect(mes_user.content).to eq(content) }
      end
      
      describe "and edits his message with an empty one" do
        before do
          fill_in "MathInputMessage#{mes_user.id}", with: ""
          click_button "SubmitMessage#{mes_user.id}"
          mes_user.reload
        end
        it { should have_content("Message doit être rempli") }
        specify { expect(mes_user.content).not_to eq("") }
      end
      
      describe "and writes a new message" do
        before do
          fill_in "MathInputNewMessage", with: content2
          click_button "Poster"
        end
        it { should have_content("Votre message a bien été posté.") }
        specify { expect(sub.messages.order(:id).last.content).to eq(content2) }
      end
      
      describe "and writes an empty message" do
        before do
          fill_in "MathInputNewMessage", with: ""
          click_button "Poster"
        end
        it { should have_content("Message doit être rempli") }
        specify { expect(sub.messages.order(:id).last.content).not_to eq("") }
      end
    end
  end

  describe "admin" do
    before { sign_in admin }

    describe "visits the subject" do
      before { visit subject_path(sub) }
      it do
        should have_link("LinkEditMessage#{mes.id}")
        should have_link("LinkDeleteMessage#{mes.id}")
        should have_button("SubmitMessage#{mes.id}")
        should have_link("LinkEditMessage#{mes_admin.id}")
        should have_link("LinkDeleteMessage#{mes_admin.id}")
        should have_button("SubmitMessage#{mes_admin.id}")
        should have_no_link("LinkEditMessage#{mes_other_admin.id}")
        should have_no_link("LinkDeleteMessage#{mes_other_admin.id}")
        should have_no_button("SubmitMessage#{mes_other_admin.id}")
      end
      
      specify { expect { click_link("LinkDeleteMessage#{mes.id}") }.to change(Message, :count).by(-1) }
      specify {	expect { click_link("LinkDeleteMessage#{mes_admin.id}") }.to change(Message, :count).by(-1) }
      
      describe "and edits the message of a student" do
        before do
          fill_in "MathInputMessage#{mes.id}", with: content
          click_button "SubmitMessage#{mes.id}"
          mes.reload
        end
        it { should have_content("Votre message a bien été modifié.") }
        specify { expect(mes.content).to eq(content) }
      end
      
      describe "and edits his own message" do
        before do
          fill_in "MathInputMessage#{mes_admin.id}", with: content
          click_button "SubmitMessage#{mes_admin.id}"
          mes_admin.reload
        end
        it { should have_content("Votre message a bien été modifié.") }
        specify { expect(mes_admin.content).to eq(content) }
      end
    end
  end

  describe "root" do
    before { sign_in root }
    
    describe "visits the subject" do
      before { visit subject_path(sub2) }
      it do
        should have_link("LinkEditMessage#{mes_other_root.id}")
        should have_link("LinkDeleteMessage#{mes_other_root.id}")
        should have_button("SubmitMessage#{mes_other_root.id}")
      end
      
      specify { expect { click_link("LinkDeleteMessage#{mes_other_root.id}") }.to change(Message, :count).by(-1) }
      
      describe "and edits the message of another root" do
        before do
          fill_in "MathInputMessage#{mes_other_root.id}", with: content
          click_button "SubmitMessage#{mes_other_root.id}"
          mes_other_root.reload
        end
        it { should have_content("Votre message a bien été modifié.") }
        specify { expect(mes_other_root.content).to eq(content) }
      end
    end
  end
end
