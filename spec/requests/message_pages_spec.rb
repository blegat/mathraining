# -*- coding: utf-8 -*-
require "spec_helper"

describe "Message pages" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:other_admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:sub) { FactoryGirl.create(:subject) }
  let(:mes) { FactoryGirl.create(:message) }
  let(:mes_user) { FactoryGirl.create(:message, user: user) }
  let(:mes_admin) { FactoryGirl.create(:message, user: admin) }
  let(:mes_other_admin) { FactoryGirl.create(:message, user: other_admin) }
  let(:mes_other_root) { FactoryGirl.create(:message, user: other_root) }
  let(:content) { "Ma réponse" }
  let(:newcontent) { "Ma nouvelle réponse" }
  
  #describe "visitor" do 
  #  describe "tries to create a message" do
  #    before { visit new_subject_message_path(sub) }
  #    it { should_not have_selector("h1", text: "Répondre") }
  #  end
  #end
  
  #describe "user" do
  #  before { sign_in user }
  #  describe "creates a message" do
  #    before { create_message(sub, content) }
  #    it { should have_selector("div", text: content) }
  #  end
  #
  #  describe "edits his message" do
  #    before { update_message(mes_user.subject, mes_user, newcontent) }
  #    it { should have_selector("div", text: newcontent) }
  #  end
  #  
  #  describe "tries to edit the message of someone else" do
  #    before { visit edit_subject_message_path(mes.subject, mes) }
  #    it { should_not have_selector("h1", text: "Modifier un message") }
  #  end
  #end

  describe "admin" do
    before { sign_in admin }

    describe "deletes the message of a student" do
      before { visit subject_path(mes.subject) }
      specify { expect { click_link("Supprimer ce message") }.to change(Message, :count).by(-1) }
    end
    
    #describe "edits the message of a student" do
    #  before { update_message(mes.subject, mes, newcontent) }
    #  it { should have_selector("div", text: newcontent) }
    #end

    describe "deletes his message" do
      before { visit subject_path(mes_admin.subject) }
      specify {	expect { click_link("Supprimer ce message") }.to change(Message, :count).by(-1) }
    end
    
    #describe "edits his message" do
    #  before { update_message(mes_admin.subject, mes_admin, newcontent) }
    #  it { should have_selector("div", text: newcontent) }
    #end
    
    #describe "tries to edit the message of another admin" do
    #  before { visit edit_subject_message_path(mes_other_admin.subject, mes_other_admin) }
    #  it { should_not have_selector("h1", text: "Modifier un message") }
    #end
  end

  describe "root" do
    before { sign_in root }
    describe "deletes the message of another root" do
      before { visit subject_path(mes_other_root.subject) }
      specify { expect { click_link("Supprimer ce message") }.to change(Message, :count).by(-1) }
    end
    
    #describe "edits the message of another root" do
    #  before { update_message(mes_other_root.subject, mes_other_root, newcontent) }
    #  it { should have_selector("div", text: newcontent) }
    #end
  end
end
