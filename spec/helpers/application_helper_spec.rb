require "spec_helper"

describe ApplicationHelper do

  describe "full_title" do
    it "should include the page title" do
      expect(full_title("foo")).to include("foo")
    end

    it "should not include a bar for the home page" do
      expect(full_title("")).not_to include("|")
    end
  end
end
