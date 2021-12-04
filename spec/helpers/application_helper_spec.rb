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
  
  describe "errors formatting" do
    let!(:error1) { "La date n'est pas valide" }
    let!(:error2) { "Contenu doit être rempli" }
    it do
      expect(errors_to_list([])).to eq("Une erreur est survenue.")
      msg = errors_to_list([error1]) 
      expect(msg).to include("Une erreur est survenue.")
      expect(msg).to include(error1)
      msg = errors_to_list([error1, error2])
      expect(msg).to include("Plusieurs erreurs sont survenues.")
      expect(msg).to include(error1)
      expect(msg).to include(error2)
    end
  end
end
