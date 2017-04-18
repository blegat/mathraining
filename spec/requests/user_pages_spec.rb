# -*- coding: utf-8 -*-
require 'spec_helper'

describe "User pages" do

  subject { page }

  describe "admin deletes" do 
  	let(:admin) { FactoryGirl.create(:admin) }  
    let(:user) { FactoryGirl.create(:user) } 
    
    before do
		  sign_in admin
		end
		
		describe "a student" do
			before do
				visit user_path(user)
			end
			it { should_not have_link("Supprimer") }
    end
    
    describe "himself" do
    	before do
				visit user_path(admin)
			end
      it { should_not have_link("Supprimer") }
    end

  end
  
  describe "root deletes" do 
    let(:user) { FactoryGirl.create(:user) } 
    let(:root) { FactoryGirl.create(:root) }  
    let(:other_root) { FactoryGirl.create(:root) }  
    let(:admin) { FactoryGirl.create(:admin) }  
    
    before do
		  sign_in root
		  visit user_path(user)
		end
    
    describe "a student" do
    	before do
    		visit user_path(user)
    	end
    	specify do
    		expect { click_link "Supprimer" }.to change(User, :count).by(-1)
    	end
    end
    
    describe "an admin" do
    	before do
    		visit user_path(admin)
    	end
    	specify do
    		expect { click_link "Supprimer" }.to change(User, :count).by(-1)
    	end
    end
    
    describe "an other root" do
    	before do
    		visit user_path(other_root)
    	end
    	it { should_not have_link("Supprimer") }
    end

  end

  describe "index" do
    let (:user) { FactoryGirl.create(:user) }
    before(:all) { 30.times { FactoryGirl.create(:user) } }
    after(:all)  { User.delete_all }

    before(:each) do
      sign_in user
      visit users_path
    end

    it { should have_selector('h1', text: 'Scores') }
  end

  describe "profile page" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }

    before do
      sign_in(user)
      visit user_path(other_user)
    end

    it { should have_selector('h1', text: other_user.name) }

  end

  describe "signup" do
    before { visit signup_path }

    let(:submit) { "Créer mon compte" }

    describe "with invalid information" do
      it "should not create a user" do
        expect { click_button submit }.not_to change(User, :count)
      end
      describe "after submission" do
        before { click_button submit }

        it { should have_selector('h1', text: 'Inscription') }
        it { should have_content('erreur') }
      end
    end

    describe "with valid information" do
      before do
        fill_in "Prénom", with: "Example"
        fill_in "Nom", with: "User"
        # Il y a deux fois ces champs (pour la connexion et l'inscription)
        page.all(:fillable_field, 'Email').last.set("user@example.com")
        page.all(:fillable_field, 'Mot de passe').last.set("foobar")
        fill_in "Confirmation du mot de passe", with: "foobar"
      end

      it "should create a user" do
        expect { click_button submit }.to change(User, :count).by(1)
      end
      describe "after saving the user" do
        before { click_button submit }
        it { should have_content('confirmer votre inscription') }
      end
    end
  end
  
  describe "edit" do
    let(:user) { FactoryGirl.create(:user) }
    before do
      sign_in user
      visit edit_user_path(user)
    end

    describe "page" do
      it { should have_selector('h1', text: "Actualisez votre profil") }
    end

    describe "with valid information" do
      before { click_button "Mettre à jour" }

      it { should have_content('bien') }
    end
    
    describe "with new valid information" do
      let(:new_first_name)  { "New First Name" }
      let(:new_last_name)  { "New Last Name" }
      let(:new_name)  { "#{new_first_name} #{new_last_name}" }
      let(:new_email) { "new@example.com" }
      before do
        fill_in "Prénom", with: new_first_name
        fill_in "Nom", with: new_last_name
        fill_in "Email", with: new_email
        fill_in "Mot de passe", with: user.password
        fill_in "Confirmation du mot de passe", with: user.password
        click_button "Mettre à jour"
      end

      it { should have_selector('h1', text: 'Actualités') }
      it { should have_selector('div.alert.alert-success') }
      it { should have_link('Déconnexion', href: signout_path) }
      specify { expect(user.reload.first_name).to eq(new_first_name) }
      specify { expect(user.reload.last_name).to eq(new_last_name) }
      specify { expect(user.reload.name).to eq(new_name) }
      specify { expect(user.reload.email).to eq(new_email) }
    end
  end

end
