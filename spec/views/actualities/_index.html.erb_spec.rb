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
      assign(:current_user, admin)
    end
    
    it "renders the actuality and the add button" do
      render partial: "actualities/index"
      expect(response).to render_template(:partial => "actualities/_show", :locals => {actuality: actuality})
      expect(rendered).to have_button("Ajouter une actualité")
    end
  end
  
  context "if the user is not an admin" do
    before do
      assign(:current_user, user)
    end
    
    it "renders the actuality and not the add button" do
      render partial: "actualities/index"
      expect(response).to render_template(:partial => "actualities/_show", :locals => {actuality: actuality})
      expect(rendered).to have_no_button("Ajouter une actualité")
    end
  end
  
  context "if the user is not signed in" do    
    it "renders the actuality and not the add button" do
      render partial: "actualities/index"
      expect(response).to render_template(:partial => "actualities/_show", :locals => {actuality: actuality})
      expect(rendered).to have_no_button("Ajouter une actualité")
    end
  end
end
