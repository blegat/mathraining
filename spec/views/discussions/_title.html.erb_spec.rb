# -*- coding: utf-8 -*-
require "spec_helper"

describe "discussions/_title.html.erb", type: :view, discussion: true do

  subject { rendered }

  let(:user) { FactoryGirl.create(:user) }
  
  before { sign_in_view(user) }
  
  context "if the user receives email for new messages" do
    before { user.update_attribute(:follow_message, true) }
      
    it "renders the button to stop" do
      render partial: "discussions/title"
      should have_button("Ne plus m'avertir par e-mail")
      should have_no_button("M'avertir des nouveaux messages par e-mail")
    end
  end
  
  context "if the user does not receive email for new messages" do
    before { user.update_attribute(:follow_message, false) }
      
    it "renders the button to receive emails" do
      render partial: "discussions/title"
      should have_no_button("Ne plus m'avertir par e-mail")
      should have_button("M'avertir des nouveaux messages par e-mail")
    end
  end
end
