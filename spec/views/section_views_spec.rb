# -*- coding: utf-8 -*-
require "spec_helper"

describe "Section views" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:advanced_user) { FactoryGirl.create(:advanced_user) }
  let(:section) { FactoryGirl.create(:section) }
  let(:fondation) { FactoryGirl.create(:fondation_section) }
  
  describe "visitor" do
    describe "visit section/show" do
      before { visit section_path(section) }
      it { should have_selector("h1", text: section.name) }
      it { should_not have_link("Modifier l'introduction") }
      it { should_not have_button("Ajouter un chapitre") }
    end
    
    describe "visit fondation section/show" do
      before { visit section_path(fondation) }
      it { should have_selector("h1", text: fondation.name) }
    end
    
    describe "visit section/showpb" do
      before { visit pb_sections_path(section) }
      it { should have_selector("h1", text: section.name) }
      it { should have_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs connectés et ayant un score d'au moins 200.") } 
    end
  end

  describe "noob user" do
    before { sign_in user }
    
    describe "visit sections/index" do
      before { visit section_path(section) }
      it { should have_selector("h1", text: section.name) }
      it { should_not have_link("Modifier l'introduction") }
      it { should_not have_button("Ajouter un chapitre") }
    end
    
    describe "visit section/showpb" do
      before { visit pb_sections_path(section) }
      it { should have_selector("h1", text: section.name) }
      it { should have_selector("div", text: "Les problèmes ne sont pas accessibles aux utilisateurs ayant un score inférieur à 200.") } 
    end
  end
  
  describe "advanced user" do
    before { sign_in advanced_user }
    
    describe "visit section/showpb" do
      before { visit pb_sections_path(section) }
      it { should have_selector("h1", text: section.name) }
      it { should_not have_selector("div", text: "Les problèmes ne sont accessibles qu'aux utilisateurs connectés et ayant un score d'au moins 200.") } 
    end
  end

  describe "admin" do
    before { sign_in admin }
    
    describe "visit sections/index" do
      before { visit section_path(section) }
      it { should have_selector("h1", text: section.name) }
      it { should have_link("Modifier l'introduction") }
      it { should have_button("Ajouter un chapitre") }
    end
  end
end
