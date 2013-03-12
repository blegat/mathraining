require "spec_helper"

describe TheoriesController do
  describe "routing" do

    it "routes to #index" do
      get("/theories").should route_to("theories#index")
    end

    it "routes to #new" do
      get("/theories/new").should route_to("theories#new")
    end

    it "routes to #show" do
      get("/theories/1").should route_to("theories#show", :id => "1")
    end

    it "routes to #edit" do
      get("/theories/1/edit").should route_to("theories#edit", :id => "1")
    end

    it "routes to #create" do
      post("/theories").should route_to("theories#create")
    end

    it "routes to #update" do
      put("/theories/1").should route_to("theories#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/theories/1").should route_to("theories#destroy", :id => "1")
    end

  end
end
