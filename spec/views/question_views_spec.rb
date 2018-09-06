# -*- coding: utf-8 -*-
require "spec_helper"

describe "Exercise views" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:other_admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:section) { FactoryGirl.create(:section) }
  let(:online_chapter) { FactoryGirl.create(:chapter, section: section, online: true) }
  let!(:online_exercise) { FactoryGirl.create(:question, chapter: online_chapter, online: true, position: 1) }
  let!(:offline_exercise) { FactoryGirl.create(:question, chapter: online_chapter, online: false, position: 2) }

  describe "visitor" do
    describe "visits online exercise" do
      before { visit_question(online_exercise) }
      it { should have_selector("div", text: online_exercise.statement) }
    end
    
    describe "visits offline exercise" do
      before { visit_question(offline_exercise) }
      it { should_not have_selector("div", text: offline_exercise.statement) }
    end
  end
  
  describe "user" do
    before { sign_in user }
    describe "visits online exercise" do
      before { visit_question(online_exercise) }
      it { should have_selector("div", text: online_exercise.statement) }
      it { should_not have_link("Modifier cet exercice") }
      it { should_not have_link("bas") }
    end
  end
  
  describe "admin" do
    before { sign_in admin }
    describe "visits online exercise" do
      before { visit_question(online_exercise) }
      it { should have_selector("div", text: online_exercise.statement) }
      it { should have_link("Modifier cet exercice") }
      it { should have_link("bas") }
      it { should_not have_link("haut") }
    end
    
    describe "visits offline exercise" do
      before { visit_question(offline_exercise) }
      it { should have_selector("div", text: offline_exercise.statement) }
      it { should have_link("Modifier cet exercice") }
      it { should_not have_link("bas") }
      it { should have_link("haut") }
    end
  end
end
