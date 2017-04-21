# -*- coding: utf-8 -*-
require "spec_helper"

describe "Section views" do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:section) { FactoryGirl.create(:section) }
  
  describe "visitor" do
    describe "visit sections/index" do
      before { visit section_path(section) }
      it { should have_selector("h1", text: section.name) }
      it { should_not have_link("Modifier l'introduction") }
      it { should_not have_button("Ajouter un chapitre") }
    end
  end

  describe "user" do
    before { sign_in user }
    
    describe "visit sections/index" do
      before { visit section_path(section) }
      it { should have_selector("h1", text: section.name) }
      it { should_not have_link("Modifier l'introduction") }
      it { should_not have_button("Ajouter un chapitre") }
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
