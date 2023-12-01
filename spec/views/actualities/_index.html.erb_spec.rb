# -*- coding: utf-8 -*-
require "spec_helper"

describe "actualities/_index.html.erb", type: :view, actuality: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:actuality) { FactoryGirl.create(:actuality) }
  
  before do
    assign(:actualities, Actuality.paginate(:page => 1, :per_page => 5))
  end
  
  context "if the user is an admin" do
    before do
      assign(:signed_in, true)
      assign(:current_user, admin)
    end
    
    it "renders the actuality and the modify button" do
      render partial: "actualities/index"
      expect(rendered).to have_content(actuality.content)
      expect(rendered).to have_button("Ajouter une actualité")
    end
  end
  
  context "if the user is not an admin" do
    before do
      assign(:signed_in, true)
      assign(:current_user, user)
    end
    
    it "renders the actuality and not the modify button" do
      render partial: "actualities/index"
      expect(rendered).to have_content(actuality.content)
      expect(rendered).to have_no_button("Ajouter une actualité")
    end
  end
  
  context "if the user is not signed in" do
    before do
      assign(:signed_in, false)
    end
    
    it "renders the actuality and not the modify button" do
      render partial: "actualities/index"
      expect(rendered).to have_content(actuality.content)
      expect(rendered).to have_no_button("Ajouter une actualité")
    end
  end
end
