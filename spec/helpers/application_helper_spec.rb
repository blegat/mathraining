require "spec_helper"

describe ApplicationHelper do

  describe "full_title" do
    it "should include the page title" do
      expect(full_title("foo")).to include("foo")
      expect(full_title("foo")).to include("Mathraining")
    end

    it "should not include a bar for the home page" do
      expect(full_title("")).not_to include("|")
    end
  end
  
  describe "dates formatting" do
    let!(:date) { Time.zone.parse('12-06-2009 21:50:08') }
    
    it do
      expect(write_hour(date)).to eq("21h50")
      expect(write_hour_only(date)).to eq("21h")
      expect(write_date(date)).to eq("12 juin 2009 à 21h50")
      expect(write_date_only_small(date)).to eq("12/06/09")
      expect(write_date_with_day(date)).to eq("vendredi 12 juin 2009 à 21h50")
      expect(write_date_only_with_day(date)).to eq("vendredi 12 juin 2009")
    end
  end
end
