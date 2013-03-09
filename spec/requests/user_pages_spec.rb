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
      expect { delete user_path(admin) }.not_to change(User, :count)
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

    it { should have_selector('title', text: 'Utilisateurs') }
    it { should have_selector('h1',    text: 'Utilisateurs') }

    describe "pagination" do

      it { should have_selector('div.pagination') }

      it "should list each user" do
        User.paginate(page: 1).each do |user|
          page.should have_selector('li', text: user.name)
        end
      end
    end
    describe "delete links" do

      it { should_not have_link('Supprimer') }

      describe "as an admin user" do
        let(:admin) { FactoryGirl.create(:admin) }
        before do
          sign_in admin
          visit users_path
        end

        it { should have_link('Supprimer', href: user_path(User.first)) }
        it "should be able to delete another user" do
          expect { click_link('Supprimer') }.to change(User, :count).by(-1)
        end
        it { should_not have_link('Supprimer', href: user_path(admin)) }
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
    it { should have_selector('title', text: other_user.name) }

  end

  describe "signup page" do
    before { visit signup_path }

    it { should have_selector('h1',    text: 'Inscription') }
    it { should have_selector('title', text: full_title('Inscription')) }
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

        it { should have_selector('title', text: 'Inscription') }
        it { should have_content('erreur') }
      end
    end

    describe "with valid information" do
      before do
        fill_in "Prénom",         with: "Example"
        fill_in "Nom",         with: "User"
        fill_in "Email",        with: "user@example.com"
        fill_in "Mot de passe",     with: "foobar"
        fill_in "Confirmation du mot de passe", with: "foobar"
      end

      it "should create a user" do
        expect { click_button submit }.to change(User, :count).by(1)
      end
      describe "after saving the user" do
        before { click_button submit }
        let(:user) { User.find_by_email('user@example.com') }

        it { should have_selector('title', text: user.name) }
        it { should have_selector('div.alert.alert-success', text: 'Bienvenue') }
        it { should have_link('Déconnexion') }
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
      it { should have_selector('title', text: "Actualisez votre profil") }
      it { should have_link('Modifier', href: 'http://gravatar.com/emails') }
    end

    describe "with invalid information" do
      before { click_button "Mettre à jour" }

      it { should have_content('erreur') }
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

      it { should have_selector('title', text: new_name) }
      it { should have_selector('div.alert.alert-success') }
      it { should have_link('Déconnexion', href: signout_path) }
      specify { user.reload.first_name.should  == new_first_name }
      specify { user.reload.last_name.should  == new_last_name }
      specify { user.reload.name.should  == new_name }
      specify { user.reload.email.should == new_email }
    end
  end

end
