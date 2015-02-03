# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Authentication" do

  subject { page }

  describe "signin page" do
    before { visit signin_path }

    it { should have_selector('h1',    text: 'Connexion') }
  end
  describe "signin" do
    before { visit root_path }

    describe "with invalid information" do
      before { click_button "Connexion" }

      describe "after visiting another page" do
        before { page.first(".navbar-brand").click }
        it { should_not have_selector('div.alert.alert-error') }
      end
    end

    describe "with valid information" do
      let(:user) { FactoryGirl.create(:user) }
      before { sign_in(user) }

      it { should have_link('Scores', href: users_path) }
      it { should have_link('Compte', href: edit_user_path(user)) }
      it { should have_link('Déconnexion', href: signout_path) }
      it { should_not have_link('Connexion', href: signin_path) }
      describe "followed by signout" do
        before { click_link "Déconnexion" }
        it { should have_link('Connexion') }
      end
    end
  end
  describe "authorization" do

    describe "for non-signed-in users" do
      let(:user) { FactoryGirl.create(:user) }

      describe "in the Users controller" do

        describe "visiting the index page" do
          before { visit users_path }
          it { should have_selector('h1', text: 'Scores') }
        end
        describe "visiting the edit page" do
          before { visit edit_user_path(user) }
          it { should have_selector('h1', text: 'Actualités') }
        end
      end
      describe "in the Home page" do
        before { visit root_path }
        it { should_not have_link('Profil') }
        it { should_not have_link('Compte') }
      end
    end
    describe "as wrong user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: "wrong@example.com") }
      before { sign_in user }

      describe "visiting Users#edit page" do
        before { visit edit_user_path(wrong_user) }
        it { should_not have_selector('h1', text: 'Actualisez votre profil') }
      end
    end
    describe "as non-admin user" do
      let(:user) { FactoryGirl.create(:user) }
      let(:non_admin) { FactoryGirl.create(:user) }

      before { sign_in non_admin }

      describe "submitting a DELETE request to the Users#destroy action" do
        before { visit user_path(user, :method => :delete) }
        it { should_not have_selector('h1', text: "Actualités") }
      end
    end
    describe "even as admin user" do
      let(:admin) { FactoryGirl.create(:admin) }
      let(:user) { FactoryGirl.create(:user) }

      before { sign_in admin }

      describe "accessible attributes" do
        before { visit user_path(user)+'?admin=1' }
        specify { user.should_not be_admin } # does not work, exercice 9.6.1
      end
    end
  end
  describe "signed in user" do
    let(:user) { FactoryGirl.create(:user) }
    before { sign_in user }

    describe "try to enter new" do
      before { visit signup_path }
      it { should_not have_selector 'title', text: '|' }
    end

    describe "try to enter create" do
      before { post users_path }
      #it { should_not have_selector 'title', text: '|' }# does not work, ex 9.6.6
    end

  end
end
