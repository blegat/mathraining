# -*- coding: utf-8 -*-
require "spec_helper"

describe ContestorganizationsController, type: :controller, color: true do

  let(:user) { FactoryGirl.create(:user) }
  let(:contestorganization) { FactoryGirl.create(:contestorganization) }
  
  context "if the user is not an admin" do
    before do
      sign_in_controller(user)
    end

    it "renders the error page for create" do
      post :create, params: {contestorganization: FactoryGirl.attributes_for(:contestorganization)}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for destroy" do
      delete :destroy, params: {id: contestorganization.id}
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
