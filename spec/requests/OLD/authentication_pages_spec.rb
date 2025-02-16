# -*- coding: utf-8 -*-
require "spec_helper"

describe "Authentication" do

  subject { page }
  
  let!(:user) { FactoryGirl.create(:user) }

  describe "signin button" do
    before { visit root_path }

    it { should have_link("Connexion") }
  end
  
  describe "tries to signin" do
    before { visit root_path }

    describe "with invalid information" do
      before { click_button "Connexion" }
      it { should have_error_message("invalide") }
    end

    describe "with valid information" do
      before { sign_in_with_form(user) }

      specify do
        expect(Capybara.current_session.driver.request.cookies.[]('remember_token')).to eq(user.remember_token)
        expect(page).to have_link("Scores", href: users_path)
        expect(page).to have_link("Compte", href: edit_user_path(user))
        expect(page).to have_link("Déconnexion", href: sessions_path)
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
    
    describe "to a deleted account" do
      before do
        user.update_attribute(:role, :deleted)
        sign_in_with_form(user)
      end
      it do
        should have_error_message("Email ou mot de passe invalide.")
        should have_no_content(user.fullname) # Should not be connected
      end
    end
    
    describe "to an account without confirmed email" do
      before do
        user.update_attribute(:email_confirm, false)
        sign_in_with_form(user)
      end
      it do
        should have_error_message("Vous devez activer votre compte via l'e-mail qui vous a été envoyé.")
        should have_no_content(user.fullname) # Should not be connected
      end
    end
    
    describe "to an account that was recently banned" do
      let!(:sanction) { FactoryGirl.create(:sanction, user: user, sanction_type: :ban, start_time: DateTime.now - 1.week, duration: 14, reason: "Ce compte a été désactivé jusqu'au [DATE].") }
      before { sign_in_with_form(user) }
      it do
        should have_error_message("Ce compte a été désactivé jusqu'au #{write_date_only(sanction.end_time)}")
        should have_no_content(user.fullname) # Should not be connected
      end
    end
    
    describe "to an account that was banned some time ago" do
      let!(:sanction) { FactoryGirl.create(:sanction, user: user, sanction_type: :ban, start_time: DateTime.now - 1.month, duration: 14) }
      before { sign_in_with_form(user) }
      it { should have_content(user.fullname) } # Should be connected
    end
  end
  
  describe "visits a page only for connected people" do
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
        check "header_connect_remember" # To test with "Remember me" too
        click_button "header_connect_button"
      end
      it { should have_selector("h1", text: "Forum") }
    end
  end
  
  describe "uses fast signin in test environment" do
    before do
      sign_in user
    end
    specify do
      expect(Capybara.current_session.driver.request.cookies.[]('remember_token')).to eq(user.remember_token)
    end
  end
  
  describe "tries to use fast signin in production environment" do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      sign_in user
    end
    specify do
      expect(Capybara.current_session.driver.request.cookies.[]('remember_token')).not_to eq(user.remember_token)
    end
  end
end
