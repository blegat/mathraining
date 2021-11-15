# -*- coding: utf-8 -*-
require "spec_helper"

describe "Authentication" do

  subject { page }

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
      let(:user) { FactoryGirl.create(:user) }
      before { sign_in(user) }

      it do
        should have_link("Scores", href: users_path)
        should have_link("Compte", href: edit_user_path(user))
        should have_link("Déconnexion", href: signout_path)
        should have_no_link("Connexion")
      end
      
      describe "followed by signout" do
        before { sign_out }
        it { should have_link("Connexion") }
      end
    end
  end
end
