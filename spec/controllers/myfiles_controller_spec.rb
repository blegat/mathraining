# -*- coding: utf-8 -*-
require "spec_helper"

describe MyfilesController, type: :controller, myfile: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:myfile) { FactoryGirl.create(:subjectmyfile) }
  
  context "if the user is not a root" do
    before do
      sign_in_controller(admin)
    end
    
    it "renders the error page for show" do
      get :show, params: {id: myfile.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for fake_delete" do
      get :fake_delete, params: {myfile_id: myfile.id}
      expect(response).to render_template 'errors/access_refused'
    end
    
    it "renders the error page for index" do
      get :index
      expect(response).to render_template 'errors/access_refused'
    end
  end
end
