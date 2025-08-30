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
  
  describe "ruby to javascript" do
    let!(:array_of_int) { [3, 4, 5, 6, 0] }
    let!(:array_of_string) { ["Belgique", "France", "Maroc"] }
    it do
      expect(ruby_to_javascript(array_of_int)).to eq("[3,4,5,6,0]")
      expect(ruby_to_javascript_string(array_of_string)).to eq("['Belgique','France','Maroc']")
    end
  end
  
  describe "hidden text replacement" do
    it do
      expect(process_hidden_text("[hide=Texte caché]Mon texte[/hide]", 0)).to eq(["(X0)Texte caché(Y0)Mon texte(Z0)", 1])
      expect(process_hidden_text("Avant[hide=Texte caché]Mon texte[/hide]Après", 2)).to eq(["Avant(X2)Texte caché(Y2)Mon texte(Z2)Après", 3])
      expect(process_hidden_text("[hide=Texte caché]Voici un autre : [hide=Texte caché 2]Le voilà[/hide]Haha[/hide]", 0)).to eq(["(X0)Texte caché(Y0)Voici un autre : (X1)Texte caché 2(Y1)Le voilà(Z1)Haha(Z0)", 2])
      expect(process_hidden_text("[hide=Texte caché]Premier[hide=Texte caché 2]Deuxième[hide=Texte caché 3]Troisième[/hide][/hide][hide=Texte caché 4]Quatrième[hide=Texte caché 5]Cinquième[/hide][/hide][/hide]", 0)).to eq(["(X0)Texte caché(Y0)Premier(X1)Texte caché 2(Y1)Deuxième(X2)Texte caché 3(Y2)Troisième(Z2)(Z1)(X3)Texte caché 4(Y3)Quatrième(X4)Texte caché 5(Y4)Cinquième(Z4)(Z3)(Z0)", 5])
      expect(process_hidden_text("[hide=Texte caché 1]Mon texte 1[/hide] Entre [hide=Texte caché 2]Mon texte 2[/hide]", 0)).to eq(["(X0)Texte caché 1(Y0)Mon texte 1(Z0) Entre (X1)Texte caché 2(Y1)Mon texte 2(Z1)", 2])
      expect(process_hidden_text("[hide=Texte cassé]Mon texte[/hide", 0)).to eq(["[hide=Texte cassé]Mon texte[/hide", 1]) # Does not matter that index goes up for nothing
      expect(process_hidden_text("[hide=[hide=Texte caché]Texte caché[/hide]][/hide]", 0)).to eq(["(X0)[hide=Texte caché(Y0)Texte caché(Z0)][/hide]", 1]) # Not supported
      expect(process_hidden_text("[/hide][hide=Texte caché]Mon texte[/hide][hide]", 0)).to eq(["[/hide](X0)Texte caché(Y0)Mon texte(Z0)[hide]", 1])
    end
  end
end
