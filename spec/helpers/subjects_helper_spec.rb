require "spec_helper"

describe SubjectsHelper, subject: true do

  include SubjectsHelper

  describe "dates formatting" do
    let!(:date) { Time.zone.parse('27-11-2021 14:52:31') }
    
    it do
      expect(write_date_from_now(date, date + 1.seconds)).to eq("il y a 1 seconde")
      expect(write_date_from_now(date, date + 3.seconds)).to eq("il y a 3 secondes")
      expect(write_date_from_now(date, date + 1.minutes + 3.seconds)).to eq("il y a 1 minute")
      expect(write_date_from_now(date, date + 13.minutes + 56.seconds)).to eq("il y a 13 minutes")
      expect(write_date_from_now(date, date + 1.hour + 13.minutes + 34.seconds)).to eq("il y a 1 heure, 13 minutes")
      expect(write_date_from_now(date, date + 22.hours + 1.minutes + 1.seconds)).to eq("il y a 22 heures, 1 minute")
      expect(write_date_from_now(date, date + 28.hours + 12.minutes)).to eq("27 novembre 2021 à 14h52")
    end
  end
  
  describe "problems of a section formatting" do
    it do
      expect(get_problem_category_name("Théorie des nombres")).to eq("Problèmes de théorie des nombres")
      expect(get_problem_category_name("Algèbre")).to eq("Problèmes d'algèbre")
      expect(get_problem_category_name("Combinatoire")).to eq("Problèmes de combinatoire")
      expect(get_problem_category_name("Inégalités")).to eq("Problèmes d'inégalités")
      expect(get_problem_category_name("Géométrie")).to eq("Problèmes de géométrie")
      expect(get_problem_category_name("Équations fonctionnelles")).to eq("Problèmes d'équations fonctionnelles")
    end
  end
  
  describe "category formatting" do
    let!(:subject) { FactoryBot.create(:subject, category: nil) }
    let!(:section) { FactoryBot.create(:section) }
    let!(:chapter) { FactoryBot.create(:chapter, section: section) }
    let!(:category) { FactoryBot.create(:category) }
    it "for a subject without any association" do
      expect(get_category_name(subject)).to eq("")
    end
    it "for a subject with a category" do
      subject.category = category
      expect(get_category_name(subject)).to eq(category.name)
    end
    it "for a subject with a section" do
      subject.section = section
      expect(get_category_name(subject)).to eq(section.name)
    end
    it "for a subject with a chapter" do
      subject.section = section
      subject.chapter = chapter
      expect(get_category_name(subject)).to eq(chapter.name)
    end
  end
end
