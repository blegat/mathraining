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
      before do
       click_button "Connexion"
      end
       
      it { should have_selector("div", text: "invalide") }
    end

    describe "with valid information" do
      let(:user) { FactoryGirl.create(:user) }
      before { sign_in(user) }

      it { should have_link("Scores", href: users_path) }
      it { should have_link("Compte", href: edit_user_path(user)) }
      it { should have_link("Déconnexion", href: signout_path) }
      it { should_not have_link("Connexion") }
      describe "followed by signout" do
        before { sign_out }
        it { should have_link("Connexion") }
      end
    end
  end
end
