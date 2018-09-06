# -*- coding: utf-8 -*-
require "spec_helper"

describe "User pages" do

  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }
  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:country) { FactoryGirl.create(:country) }

  describe "admin" do
    before { sign_in admin }

    describe "tries to delete a student" do
      before { visit user_path(user) }
      it { should_not have_link("Supprimer") }
    end
    
    describe "tries to delete himself" do
      before { visit user_path(admin) }
      it { should_not have_link("Supprimer") }
    end
  end

  describe "root" do
    before { sign_in root }

    describe "deletes a student" do
      before { visit user_path(user) }
      specify {	expect { click_link "Supprimer" }.to change(User, :count).by(-1) }
    end

    describe "deletes an admin" do
      before { visit user_path(admin) }
      specify { expect { click_link "Supprimer" }.to change(User, :count).by(-1) }
    end

    describe "tries to delete another root" do
      before { visit user_path(other_root) }
      it { should_not have_link("Supprimer") }
    end

    describe "deletes a student with a subject with a message (DEPENDENCY)" do
      let!(:sub) { FactoryGirl.create(:subject, user: user) }
      let!(:mes) { FactoryGirl.create(:message, subject: sub, user: other_user) }
      before { visit user_path(user) }
      specify { expect { click_link "Supprimer" }.to change(Subject, :count).by(-1) }
      specify {	expect { click_link "Supprimer" }.to change(Message, :count).by(-1) }
    end

    describe "deletes a student with a message (DEPENDENCY)" do
      let!(:mes) { FactoryGirl.create(:message, user: user) }
      before { visit user_path(user) }
      specify { expect { click_link "Supprimer" }.to change(Message, :count).by(-1) }
    end

    describe "deletes a student with a discussion with tchatmessages (DEPENDENCY)" do
      before do
        create_discussion_between(user, other_user, "Coucou mon ami", "Salut mon poto")
        visit user_path(user)
      end
      specify { expect { click_link "Supprimer" }.to change(Link, :count).by(-2) }
      specify { expect { click_link "Supprimer" }.to change(Discussion, :count).by(-1) }
      specify { expect { click_link "Supprimer" }.to change(Tchatmessage, :count).by(-2) }
    end
  end

  describe "visitor" do
    before { visit signup_path }

    describe "signup with invalid information" do
      specify { expect { click_button "Créer mon compte" }.not_to change(User, :count) }
      describe "after submission" do
        before do
          find(:css, "#consent1[value='1']").set(true)
          find(:css, "#consent2[value='2']").set(true)
          click_button "Créer mon compte"
        end
        it { should have_selector("h1", text: "Inscription") }
        it { should have_content("erreur") }
      end
    end

    describe "signup with with valid information" do
      before do
        fill_in "Prénom", with: "Example"
        fill_in "Nom", with: "User"
        select country.name, from: "Pays"
        select "1977", from: "Année de naissance"
        # Il y a deux fois ces champs (pour la connexion et l"inscription)
        page.all(:fillable_field, "Email").last.set("user@example.com")
        page.all(:fillable_field, "Confirmation de l'email").last.set("user@example.com")
        page.all(:fillable_field, "Mot de passe").last.set("foobar")
        fill_in "Confirmation du mot de passe", with: "foobar"
        find(:css, "#consent1[value='1']").set(true)
        find(:css, "#consent2[value='2']").set(true)
      end

      specify { expect { click_button "Créer mon compte" }.to change(User, :count).by(1) }
      describe "after saving the user" do
        before { click_button "Créer mon compte" }
        it { should have_content("confirmer votre inscription") }
      end
    end
  end

  describe "user" do
    let(:new_first_name)  { "New First Name" }
    let(:new_last_name)  { "New Last Name" }
    let(:new_name)  { "#{new_first_name} #{new_last_name}" }
    before { sign_in user }
    
    describe "edits his information" do
      before do
        visit edit_user_path(user)
        fill_in "Prénom", with: new_first_name
        fill_in "Nom", with: new_last_name
        fill_in "Mot de passe", with: user.password
        fill_in "Confirmation du mot de passe", with: user.password
        click_button "Mettre à jour"
        user.reload
      end
      
      it { should have_selector("h1", text: "Actualités") }
      it { should have_selector("div.alert.alert-success") }
      it { should have_link("Déconnexion", href: signout_path) }
      specify { expect(user.first_name).to eq(new_first_name) }
      specify { expect(user.last_name).to eq(new_last_name) }
      specify { expect(user.name).to eq(new_name) }
    end
  end
end
