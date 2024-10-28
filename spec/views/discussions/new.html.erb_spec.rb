# -*- coding: utf-8 -*-
require "spec_helper"

describe "discussions/new.html.erb", type: :view, discussion: true do

  subject { rendered }

  let(:user) { FactoryGirl.create(:user) }
  
  before do
    assign(:current_user, user)
    assign(:tchatmessage, Tchatmessage.new)
  end
  
  it "renders the new discussion page correctly" do
    render template: "discussions/new"
    expect(response).to render_template(:partial => "discussions/_menu")
    should have_field("qui")
    should have_field("MathInput")
    should have_button("Envoyer")
  end
end
