require "spec_helper"

describe StaticPagesController do

  describe "GET 'home'", :type => :controller do
    it "returns http success" do
      get 'home'
      expect(response).to be_successful
    end
  end

  describe "GET 'contact'", :type => :controller do
    it "returns http success" do
      get 'contact'
      expect(response).to be_successful
    end
  end

  describe "GET 'about'", :type => :controller do
    it "returns http success" do
      get 'about'
      expect(response).to be_successful
    end
  end

end
