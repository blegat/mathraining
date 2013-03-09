require "spec_helper"

describe ChaptersController do
  describe "routing" do

    it "routes to #index" do
      get("/chapters").should route_to("chapters#index")
    end

    it "routes to #new" do
      get("/chapters/new").should route_to("chapters#new")
    end

    it "routes to #show" do
      get("/chapters/1").should route_to("chapters#show", :id => "1")
    end

    it "routes to #edit" do
      get("/chapters/1/edit").should route_to("chapters#edit", :id => "1")
    end

    it "routes to #create" do
      post("/chapters").should route_to("chapters#create")
    end

    it "routes to #update" do
      put("/chapters/1").should route_to("chapters#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/chapters/1").should route_to("chapters#destroy", :id => "1")
    end

  end
end
