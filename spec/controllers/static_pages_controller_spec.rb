require 'spec_helper'

describe StaticPagesController do

  describe "GET 'home'", :type => :controller do
    it "returns http success" do
      get 'home'
      response.should be_success
    end
  end

  describe "GET 'contact'", :type => :controller do
    it "returns http success" do
      get 'contact'
      response.should be_success
    end
  end

  describe "GET 'about'", :type => :controller do
    it "returns http success" do
      get 'about'
      response.should be_success
    end
  end

end
