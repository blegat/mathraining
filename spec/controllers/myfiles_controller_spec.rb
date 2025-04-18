# -*- coding: utf-8 -*-
require "spec_helper"

describe MyfilesController, type: :controller, myfile: true do

  let(:admin) { FactoryBot.create(:admin) }
  let(:myfile) { FactoryBot.create(:messagemyfile) }
  
  context "if the user is not a root" do
    before { sign_in_controller(admin) }
    
    it { expect(response).to have_controller_index_behavior(:access_refused) }
    it { expect(response).to have_controller_show_behavior(myfile, :access_refused) }
    it { expect(response).to have_controller_put_path_behavior('fake_delete', myfile, :access_refused) }
  end
end
