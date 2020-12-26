# -*- coding: utf-8 -*-
require "spec_helper"

describe "User views" do

  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:root) { FactoryGirl.create(:root) }
  
  describe "visitor" do
    describe "visit user/index" do
      before { visit users_path }
      it { should have_selector("h1", text: "Scores") }
    end

    describe "visit user/show" do
      before { visit user_path(user) }
      it { should have_selector("span", text: user.name) }
      it { should_not have_link("Envoyer un message") }
      it { should_not have_link("Suivre") }
    end
  end
  
  describe "user" do
    before { sign_in user }
    
    describe "visit user/index" do
      before { visit users_path }
      it { should have_selector("h1", text: "Scores") }
    end

    describe "visit user/show" do
      before { visit user_path(user) }
      it { should have_selector("span", text: user.name) }
      it { should_not have_content("Connecté le") }
      it { should_not have_link("Envoyer un message") }
      it { should_not have_link("Suivre") }
      it { should_not have_content(user.email) }
    end
    
    describe "visit user/show of somebody else" do
      before { visit user_path(other_user) }
      it { should have_link("Envoyer un message") }
      it { should have_link("Suivre") }
    end
  end
  
  describe "admin" do
    before { sign_in admin }
    
    describe "visit user/index" do
      before { visit users_path }
      it { should have_selector("h1", text: "Scores") }
      it { should_not have_button("Modifier les niveaux et couleurs") }
    end   
  end
  
  describe "root" do
    before { sign_in root }
    
    describe "visit user/index" do
      before { visit users_path }
      it { should have_button("Modifier les niveaux et couleurs") }
    end
    
    describe "visit user/show" do
      before { visit user_path(user) }
      it { should have_content("Connecté le") }
      it { should have_content(user.email) }
    end 
  end
end
