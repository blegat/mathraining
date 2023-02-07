# -*- coding: utf-8 -*-
require "spec_helper"

describe "Authentication" do

  subject { page }

  describe "signin button" do
    before { visit root_path }

    it { should have_link("Connexion") }
  end
  
  describe "tries to signin" do
    let(:user) { FactoryGirl.create(:user) }
    before { visit root_path }

    describe "with invalid information" do
      before { click_button "Connexion" }
      it { should have_error_message("invalide") }
    end

    describe "with valid information" do
      before { sign_in(user) }

      specify do
        expect(Capybara.current_session.driver.request.cookies.[]('remember_token')).to eq(user.remember_token)
        expect(page).to have_link("Scores", href: users_path)
        expect(page).to have_link("Compte", href: edit_user_path(user))
        expect(page).to have_link("Déconnexion", href: signout_path)
        expect(page).to have_no_link("Connexion")
      end
      
      describe "followed by signout" do
        before { sign_out }
        specify do
          expect(Capybara.current_session.driver.request.cookies.[]('remember_token')).to eq(nil)
          expect(page).to have_link("Connexion")
        end
      end
    end
    
    describe "to an inactive account" do
      before do
        user.update_attribute(:active, false)
        sign_in(user)
      end
      it do
        should have_error_message("Ce compte a été désactivé et n'est plus accessible.")
        should have_no_content(user.fullname) # Should not be connected
      end
    end
    
    describe "to an account without confirmed email" do
      before do
        user.update_attribute(:email_confirm, false)
        sign_in(user)
      end
      it do
        should have_error_message("Vous devez activer votre compte via l'e-mail qui vous a été envoyé.")
        should have_no_content(user.fullname) # Should not be connected
      end
    end
    
    describe "to an account that was recently banned" do
      before do
        user.update_attribute(:last_ban_date, DateTime.now - 1.week)
        sign_in(user)
      end
      it do
        should have_error_message("Ce compte a été temporairement désactivé pour cause de plagiat.")
        should have_no_content(user.fullname) # Should not be connected
      end
    end
    
    describe "to an account that was banned some time ago" do
      before do
        user.update_attribute(:last_ban_date, DateTime.now - 1.month)
        sign_in(user)
      end
      it { should have_content(user.fullname) } # Should be connected
    end
  end
  
  describe "visits a page only for connected people" do
    let!(:user) { FactoryGirl.create(:user) }
    before { visit subjects_path }
    
    it do
      should have_content(error_must_be_connected)
      should have_button("connect_button")
    end
    
    describe "and signin with main form" do
      before do
        fill_in "connect_email", with: user.email
        fill_in "connect_password", with: user.password
        click_button "connect_button"
      end
      it { should have_selector("h1", text: "Forum") }
    end
    
    describe "and signin with header form" do
      before do
        click_link "Connexion"
        fill_in "header_connect_email", with: user.email
        fill_in "header_connect_password", with: user.password
        click_button "header_connect_button"
      end
      it { should have_selector("h1", text: "Forum") }
    end
  end
end
