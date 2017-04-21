# -*- coding: utf-8 -*-
require "spec_helper"

describe "Subject views" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:other_admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:sub) { FactoryGirl.create(:subject) }
  let(:sub_user) { FactoryGirl.create(:subject, user: user) }
  let(:sub_admin) { FactoryGirl.create(:subject, user: admin) }
  let(:sub_other_admin) { FactoryGirl.create(:subject, user: other_admin) }
  let(:sub_other_root) { FactoryGirl.create(:subject, user: other_root) }

  describe "visitor" do
    describe "visits subject/index" do
      before { visit subjects_path }
      it { should_not have_selector("h1", text: "Forum") }
    end

    describe "visits subject/new" do
      before { visit new_subject_path }
      it { should_not have_selector("h1", text: "Créer un sujet") }
    end

    describe "visits subject/show" do
      before { visit subject_path(sub) }
      it { should_not have_selector("div", text: "Contenu") }
    end
  end

  describe "user" do
    before { sign_in user }

    describe "visits subject/index" do
      before { visit subjects_path }
      it { should have_selector("h1", text: "Forum") }
      it { should have_link("Créer un sujet") }
    end

    describe "visits subject/show" do
      before { visit subject_path(sub_user) }
      it { should have_link("Modifier ce sujet") }
      it { should_not have_link("Supprimer ce sujet") }
    end

    describe "visits subject/show of someone else" do
      before { visit subject_path(sub) }
      it { should_not have_link("Modifier ce sujet") }
      it { should have_link("Répondre") }

      describe "tries to edit it" do
        before { visit edit_subject_path(sub) }
        it { should_not have_selector("h1", text: "Modifier un sujet") }
      end
    end
  end

  describe "admin" do
    before { sign_in admin }

    describe "visits subject/show of a student" do
      before { visit subject_path(sub) }
      it { should have_link("Modifier ce sujet") }
      it { should have_link("Supprimer ce sujet") }
    end

    describe "visits subject/show" do
      before { visit subject_path(sub_admin) }
      it { should have_link("Modifier ce sujet") }
      it { should have_link("Supprimer ce sujet") }
    end

    describe "visits subject/show of another admin" do
      before { visit subject_path(sub_other_admin) }
      it { should_not have_link("Modifier ce sujet") }
      it { should_not have_link("Supprimer ce sujet") }
      
      describe "tries to edit it" do
        before { visit edit_subject_path(sub_other_admin) }
        it { should_not have_selector("h1", text: "Modifier un sujet") }
      end
    end
  end

  describe "root" do
    before { sign_in root }

    describe "visits subject/show of another root" do
      before { visit subject_path(sub_other_root) }
      it { should have_link("Modifier ce sujet") }
      it { should have_link("Supprimer ce sujet") }
    end
  end

end
