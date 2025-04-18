# -*- coding: utf-8 -*-
require "spec_helper"

describe "actualities/_index.html.erb", type: :view, actuality: true do

  subject { rendered }

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let!(:actuality) { FactoryBot.create(:actuality) }
  
  before { assign(:actualities, Actuality.paginate(:page => 1, :per_page => 5)) }
  
  context "if the user is an admin" do
    before { sign_in_view(admin) }
    
    it "renders the actuality and the add button" do
      render partial: "actualities/index"
      expect(response).to render_template(:partial => "actualities/_show", :locals => {actuality: actuality})
      should have_link("Ajouter une actualité")
    end
  end
  
  context "if the user is not an admin" do
    before { sign_in_view(user) }
    
    it "renders the actuality and not the add button" do
      render partial: "actualities/index"
      expect(response).to render_template(:partial => "actualities/_show", :locals => {actuality: actuality})
      should have_no_link("Ajouter une actualité")
    end
  end
  
  context "if the user is not signed in" do    
    it "renders the actuality and not the add button" do
      render partial: "actualities/index"
      expect(response).to render_template(:partial => "actualities/_show", :locals => {actuality: actuality})
      should have_no_link("Ajouter une actualité")
    end
  end
end
