# -*- coding: utf-8 -*-
require "spec_helper"

describe "Static pages" do

  let(:user) { FactoryGirl.create(:user) }
  let(:user_wepion) { FactoryGirl.create(:user, wepion: true) }
  let(:corrector) { FactoryGirl.create(:corrector) }
  let(:admin) { FactoryGirl.create(:admin) }

  subject { page }

  describe "Home page" do
    before { visit root_path }
    it { should have_selector("h1", text: "Actualités") }
  end

  describe "About page" do
    before { visit about_path }
    it { should have_selector("h1", text: "À propos") }
  end

  describe "Contact page" do
    before { visit contact_path }
    it { should have_selector("h1", text: "Contact") }
  end
	
  describe "Contact page while site is under maintenance" do
    before do
      Globalvariable.create(:key => "under_maintenance", :value => true, :message => "Site en maintenance !")
      visit contact_path
    end
    it do
      should have_selector("h1", text: "Actualités")
      should have_info_message("Site en maintenance !")
    end
  end
  
  describe "When website is temporary closed" do
    before { Globalvariable.create(:key => "temporary_closure", :value => true, :message => "Site fermé car j'en ai marre.") }
    
    describe "home page should show message" do
      before { visit root_path }
      it { should have_info_message("Site fermé car j'en ai marre.") }
    end
    
    describe "sign in should not work for a random user" do
      before do
        visit users_path
        sign_in_with_form(user, false)
      end
      it do
        should have_info_message("Site fermé car j'en ai marre.")
        should have_selector("h1", text: "Scores")
      end
    end
    
    describe "sign in should not work for a wepion user" do
      before do
        visit users_path
        sign_in_with_form(user_wepion, false)
      end
      it do
        should have_no_content("Site fermé car j'en ai marre.")
        should have_selector("h1", text: "Scores")
      end
    end
    
    describe "sign in should not work for a corrector" do
      before do
        visit users_path
        sign_in_with_form(corrector, false)
      end
      it do
        should have_no_content("Site fermé car j'en ai marre.")
        should have_selector("h1", text: "Scores")
      end
    end
    
    describe "sign in should not work for an admin" do
      before do
        visit users_path
        sign_in_with_form(admin, false)
      end
      it do
        should have_no_content("Site fermé car j'en ai marre.")
        should have_selector("h1", text: "Scores")
      end
    end
  end
  
  describe "when website is temporary closed while visiting it" do
    before do
      sign_in user
      Globalvariable.create(:key => "temporary_closure", :value => true, :message => "Site fermé car j'en ai marre.")
      visit users_path
    end
    it do
      should have_info_message("Site fermé car j'en ai marre.")
      should have_selector("h1", text: "Actualités")
    end
  end

  describe "Any page, starting benchmark" do
    before { visit root_path(:start_benchmark => 1) }
    it { should have_content("Temps total de chargement") }
	  
    describe "visiting another page" do
      before { visit contact_path }
      it { should have_content("Temps total de chargement") }
	    
      describe "and stopping benchmark" do
        before { visit about_path(:stop_benchmark => 1) }
        it { should have_no_content("Temps total de chargement") }
	      
        describe "and visiting another page" do
          before { visit users_path }
          it { should have_no_content("Temps total de chargement") }
        end
      end
    end
  end
end
