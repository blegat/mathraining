# -*- coding: utf-8 -*-
require "spec_helper"

describe "Static pages", static: true do
  
  let(:closure_message) { "Site fermé temporairement !" }

  subject { page }
  
  describe "Error page" do
    before { visit (users_path + "wrongpath") }
    it { should have_content(error_access_refused) }
  end

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
      Globalvariable.create(:key => "under_maintenance", :value => true, :message => closure_message)
      visit contact_path
    end
    it do
      should have_selector("h1", text: "Actualités")
      should have_info_message(closure_message)
    end
  end
  
  describe "When website is temporary closed while visiting it" do
    let(:user) { FactoryBot.create(:user) }
    before do
      sign_in user
      Globalvariable.create(:key => "temporary_closure", :value => true, :message => closure_message)
      visit users_path
    end
    it do
      should have_info_message(closure_message)
      should have_selector("h1", text: "Actualités")
    end
  end

  describe "Any page, starting time benchmark" do
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
