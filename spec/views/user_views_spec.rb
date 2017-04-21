# -*- coding: utf-8 -*-
require "spec_helper"

describe "User views" do

  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  
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
      visit user_path(user)
    end

    it { should have_selector("h1", text: user.name) }
  end
end
