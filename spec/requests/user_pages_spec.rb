# -*- coding: utf-8 -*-
require "spec_helper"

describe "User pages" do

  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  let(:other_user) { FactoryGirl.create(:user) }
  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }

  describe "admin deletes" do
    before { sign_in admin }

    describe "a student" do
      before { visit user_path(user) }
      it { should_not have_link("Supprimer") }
    end
    
    describe "himself" do
      before { visit user_path(admin) }
      it { should_not have_link("Supprimer") }
    end

  end

  describe "root deletes" do
    before { sign_in root }

    describe "a student" do
      before { visit user_path(user) }
      specify {	expect { click_link "Supprimer" }.to change(User, :count).by(-1) }
    end

    describe "an admin" do
      before { visit user_path(admin) }
      specify { expect { click_link "Supprimer" }.to change(User, :count).by(-1) }
    end

    describe "an other root" do
      before { visit user_path(other_root) }
      it { should_not have_link("Supprimer") }
    end

    describe "a student with a subject with a message (DEPENDENCY)" do
      let!(:sub) { FactoryGirl.create(:subject, user: user) }
      let!(:mes) { FactoryGirl.create(:message, subject: sub, user: other_user) }
      before { visit user_path(user) }
      specify { expect { click_link "Supprimer" }.to change(Subject, :count).by(-1) }
      specify {	expect { click_link "Supprimer" }.to change(Message, :count).by(-1) }
    end

    describe "a student with a message (DEPENDENCY)" do
      let!(:mes) { FactoryGirl.create(:message, user: user) }
      before { visit user_path(user) }
      specify { expect { click_link "Supprimer" }.to change(Message, :count).by(-1) }
    end

    describe "a student with a discussion with tchatmessages (DEPENDENCY)" do
      before do
        create_discussion_between(user, other_user, "Coucou mon ami", "Salut mon poto")
        visit user_path(user)
      end
      specify { expect { click_link "Supprimer" }.to change(Link, :count).by(-2) }
      specify { expect { click_link "Supprimer" }.to change(Discussion, :count).by(-1) }
      specify { expect { click_link "Supprimer" }.to change(Tchatmessage, :count).by(-2) }
    end
  end

  describe "index" do
    before(:all) { 30.times { FactoryGirl.create(:user) } }
    after(:all)  { User.delete_all }

    before(:each) do
      sign_in user
      visit users_path
    end

    it { should have_selector("h1", text: "Scores") }
  end

  describe "profile page" do
    before do
      sign_in(user)
      visit user_path(other_user)
    end

    it { should have_selector("h1", text: other_user.name) }
  end

  describe "signup" do
    before { visit signup_path }

    let(:submit) { "Créer mon compte" }

    describe "with invalid information" do
      specify { expect { click_button submit }.not_to change(User, :count) }
      describe "after submission" do
        before { click_button submit }

        it { should have_selector("h1", text: "Inscription") }
        it { should have_content("erreur") }
      end
    end

    describe "with valid information" do
      before do
        fill_in "Prénom", with: "Example"
        fill_in "Nom", with: "User"
        # Il y a deux fois ces champs (pour la connexion et l"inscription)
        page.all(:fillable_field, "Email").last.set("user@example.com")
        page.all(:fillable_field, "Mot de passe").last.set("foobar")
        fill_in "Confirmation du mot de passe", with: "foobar"
      end

      specify { expect { click_button submit }.to change(User, :count).by(1) }
      describe "after saving the user" do
        before { click_button submit }
        it { should have_content("confirmer votre inscription") }
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
      it { should have_selector("h1", text: "Actualisez votre profil") }
    end

    describe "with valid information" do
      before { click_button "Mettre à jour" }

      it { should have_content("bien") }
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

      it { should have_selector("h1", text: "Actualités") }
      it { should have_selector("div.alert.alert-success") }
      it { should have_link("Déconnexion", href: signout_path) }
      specify { expect(user.reload.first_name).to eq(new_first_name) }
      specify { expect(user.reload.last_name).to eq(new_last_name) }
      specify { expect(user.reload.name).to eq(new_name) }
      specify { expect(user.reload.email).to eq(new_email) }
    end
  end

end
