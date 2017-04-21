# -*- coding: utf-8 -*-
require "spec_helper"

describe "Subject pages" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:other_admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:category) { FactoryGirl.create(:category) }
  let!(:sub) { FactoryGirl.create(:subject) }
  let(:sub_user) { FactoryGirl.create(:subject, user: user) }
  let(:sub_admin) { FactoryGirl.create(:subject, user: admin) }
  let(:sub_other_admin) { FactoryGirl.create(:subject, user: other_admin) }
  let(:sub_other_root) { FactoryGirl.create(:subject, user: other_root) }
  let!(:exercise) { FactoryGirl.create(:exercise) }
  let(:title) { "Mon titre" }
  let(:content) { "Mon message" }
  let(:newtitle) { "Mon nouveau titre" }
  let(:newcontent) { "Mon nouveau message" }
  
  describe "visitor" do
    describe "tries to create a subject" do
      before { visit new_subject_path }
      it { should_not have_selector("h1", text: "Créer un sujet") }
    end
  end
  
  describe "user" do
    before { sign_in user }

    describe "creates a subject" do
      before { create_subject(category, title, content) }
      it { should have_selector("div", text: content) }
    end

    describe "edits his subject" do
      before { update_subject(sub_user, newtitle, newcontent) }
      it { should have_selector("div", text: newcontent) }
    end

    describe "tries to edit the subject of someone else" do
      before { visit edit_subject_path(sub) }
      it { should_not have_selector("h1", text: "Modifier un sujet") }
    end

    # A test with javascript seems too ambitious for the moment...
    #describe "creates a subject associated to an exercise" do
    #	before do
    #		Capybara.current_driver = Capybara.javascript_driver
    #		visit new_subject_path
    #		select exercise.chapter.section, from: "Catégorie"
    #		select exercise.chapter, from: "Chapitre"
    #		select exercise.name, from: "Exercice"
    #		fill_in "Titre", with: title
    #		fill_in "MathInput", with: content
    #		click_button "Créer"
    #	end
    #	it { should have_selector("div", text: content }
    #end
  end

  describe "admin" do
    before { sign_in admin }

    describe "deletes the subject of a student" do
      before { visit subject_path(sub) }
      specify{ expect { click_link("Supprimer ce sujet") }.to change(Subject, :count).by(-1) }
    end
    
    describe "edits the subject of a student" do
      before { update_subject(sub, newtitle, newcontent) }
      it { should have_selector("div", text: newcontent) }
    end

    describe "deletes his subject" do
      before { visit subject_path(sub_admin) }
      specify {	expect { click_link("Supprimer ce sujet") }.to change(Subject, :count).by(-1) }
    end
    
    describe "edits his subject" do
      before { update_subject(sub_admin, newtitle, newcontent) }
      it { should have_selector("div", text: newcontent) }
    end
    
    describe "tries to edit the subject of another admin" do
      before { visit edit_subject_path(sub_other_admin) }
      it { should_not have_selector("h1", text: "Modifier un sujet") }
    end

    describe "deletes a subject with a message (DEPENDENCY)" do
      let!(:mes) { FactoryGirl.create(:message, subject: sub) }
      before { visit subject_path(sub) }
      specify {	expect { click_link("Supprimer ce sujet") }.to change(Message, :count).by(-1) }
    end
  end

  describe "root" do
    before { sign_in root }

    describe "deletes the subject of another root" do
      before { visit subject_path(sub_other_root) }
      specify { expect { click_link("Supprimer ce sujet") }.to change(Subject, :count).by(-1) }
    end
    
    describe "edits the subject of another admin" do
      before { update_subject(sub_other_root, newtitle, newcontent) }
      it { should have_selector("div", text: newcontent) }
    end
  end

end
