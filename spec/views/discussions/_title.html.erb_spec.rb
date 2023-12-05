# -*- coding: utf-8 -*-
require "spec_helper"

describe "discussions/_title.html.erb", type: :view, discussion: true do

  let(:user) { FactoryGirl.create(:user) }
  
  before do
    assign(:signed_in, true)
    assign(:current_user, user)
  end
  
  context "if the user receives email for new messages" do
    before do
      user.update_attribute(:follow_message, true)
    end
      
    it "renders the button to stop" do
      render partial: "discussions/title"
      expect(rendered).to have_button("Ne plus m'avertir par e-mail")
      expect(rendered).to have_no_button("M'avertir des nouveaux messages par e-mail")
    end
  end
  
  context "if the user does not receive email for new messages" do
    before do
      user.update_attribute(:follow_message, false)
    end
      
    it "renders the button to receive emails" do
      render partial: "discussions/title"
      expect(rendered).to have_no_button("Ne plus m'avertir par e-mail")
      expect(rendered).to have_button("M'avertir des nouveaux messages par e-mail")
    end
  end
end
