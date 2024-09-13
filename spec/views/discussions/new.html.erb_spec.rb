# -*- coding: utf-8 -*-
require "spec_helper"

describe "discussions/new.html.erb", type: :view, discussion: true do

  let(:user) { FactoryGirl.create(:user) }
  
  before do
    assign(:signed_in, true)
    assign(:current_user, user)
    assign(:tchatmessage, Tchatmessage.new)
  end
  
  it "renders the new discussion page correctly" do
    render template: "discussions/new"
    expect(response).to render_template(:partial => "discussions/_menu")
    expect(rendered).to have_field("qui")
    expect(rendered).to have_field("MathInput")
    expect(rendered).to have_button("Envoyer")
  end
end
