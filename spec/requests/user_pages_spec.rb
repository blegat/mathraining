# -*- coding: utf-8 -*-
require 'spec_helper'

describe "User pages" do

  subject { page }

  describe "delete" do
    let (:admin) { FactoryGirl.create(:admin) }
    before do
      sign_in admin
    end
    specify "an admin should not be able to destroy himself" do
      expect { visit user_path(admin, :method => :delete) }.not_to change(User, :count)
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

    it { should have_selector('h1',    text: 'Scores') }

    describe "pagination" do


      it "should list each user" do
        User.where(:admin => false).each do |user|
          if user.rating > 0
            page.should have_selector('tr', text: user.name)
          end
        end
      end
    end
  end

  describe "profile page" do
    let(:user) { FactoryGirl.create(:user) }
    let(:other_user) { FactoryGirl.create(:user) }

    before do
      sign_in(user)
      visit user_path(other_user)
    end

    it { should have_selector('h1',    text: other_user.name) }

  end

  describe "signup page" do
    before { visit signup_path }

    it { should have_selector('h1',    text: 'Inscription') }
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
        fill_in "Prénom",         with: "Example"
        fill_in "Nom",         with: "User"
        # IL y a deux fois ces champs :(
        page.all(:fillable_field, 'Email').last.set("user@example.com")
        page.all(:fillable_field, 'Mot de passe').last.set("foobar")
        fill_in "Confirmation du mot de passe", with: "foobar"
      end

      it "should create a user" do
        expect { click_button submit }.to change(User, :count).by(1)
      end
      describe "after saving the user" do
        before { click_button submit }
        let(:user) { User.find_by_email('user@example.com') }

        it { should have_link('Connexion') }
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
      it { should have_selector('h1',    text: "Actualisez votre profil") }
    end

    describe "with valid information" do
      before { click_button "Mettre à jour" }

      it { should have_content('bien') }
    end
    describe "with valid information" do
      let(:new_first_name)  { "New First Name" }
      let(:new_last_name)  { "New Last Name" }
      let(:new_name)  { "#{new_first_name} #{new_last_name}" }
      let(:new_email) { "new@example.com" }
      before do
        fill_in "Prénom",             with: new_first_name
        fill_in "Nom",             with: new_last_name
        fill_in "Email",            with: new_email
        fill_in "Mot de passe",         with: user.password
        fill_in "Confirmation du mot de passe", with: user.password
        click_button "Mettre à jour"
      end

      it { should have_selector('h1', text: 'Actualités') }
      it { should have_selector('div.alert.alert-success') }
      it { should have_link('Déconnexion', href: signout_path) }
      specify { user.reload.first_name.should  == new_first_name }
      specify { user.reload.last_name.should  == new_last_name }
      specify { user.reload.name.should  == new_name }
      specify { user.reload.email.should == new_email }
    end
  end

end
