# -*- coding: utf-8 -*-
require "spec_helper"

describe "Message views" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:other_root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:other_admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:sub) { FactoryGirl.create(:subject) }
  let(:mes) { FactoryGirl.create(:message) }
  let(:mes_user) { FactoryGirl.create(:message, user: user) }
  let(:mes_admin) { FactoryGirl.create(:message, user: admin) }
  let(:mes_other_admin) { FactoryGirl.create(:message, user: other_admin) }
  let(:mes_other_root) { FactoryGirl.create(:message, user: other_root) }

  describe "user" do
    before { sign_in user }
    
    describe "visits his message" do
      before { visit subject_path(mes_user.subject) }
      it { should have_link("Modifier ce message") }
      it { should_not have_link("Supprimer ce message") }
    end

    describe "visits the message of someone else" do
      before { visit subject_path(mes.subject) }
      it { should_not have_link("Modifier ce message") }
    end
  end

  describe "admin" do
    before { sign_in admin }

    describe "visits the message of a student" do
      before { visit subject_path(mes.subject) }
      it { should have_link("Modifier ce message") }
      it { should have_link("Supprimer ce message") }
    end

    describe "visits his message" do
      before { visit subject_path(mes_admin.subject) }
      it { should have_link("Modifier ce message") }
      it { should have_link("Supprimer ce message") }
    end

    describe "visits the message of another admin" do
      before { visit subject_path(mes_other_admin.subject) }
      it { should_not have_link("Modifier ce message") }
      it { should_not have_link("Supprimer ce message") }
    end
  end

  describe "root" do
    before { sign_in root }
    describe "visits the message of another root" do
      before { visit subject_path(mes_other_root.subject) }
      it { should have_link("Modifier ce message") }
      it { should have_link("Supprimer ce message") }
    end
  end
end
