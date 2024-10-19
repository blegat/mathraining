# -*- coding: utf-8 -*-
require "spec_helper"

describe "chapters/chapterstats.html.erb", type: :view, chapter: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let(:user_bad) { FactoryGirl.create(:user) }
  let!(:section) { FactoryGirl.create(:section) }
  let!(:chapter1) { FactoryGirl.create(:chapter, section: section, online: true, level: 1, position: 1, nb_tries: 9, nb_completions: 2) }
  let!(:chapter2) { FactoryGirl.create(:chapter, section: section, online: true, level: 1, position: 2, nb_tries: 8, nb_completions: 2) }
  let!(:chapter3) { FactoryGirl.create(:chapter, section: section, online: false, level: 2, position: 1, nb_tries: 0, nb_completions: 0) }
  let!(:question11_offline) { FactoryGirl.create(:exercise, chapter: chapter1, online: false, position: 1, nb_wrong: 0, nb_correct: 0, nb_first_guesses: 0) }
  let!(:question12) { FactoryGirl.create(:exercise_decimal, chapter: chapter1, online: true, position: 2, nb_wrong: 1, nb_correct: 2, nb_first_guesses: 2) }
  let!(:question21) { FactoryGirl.create(:qcm, chapter: chapter2, online: true, position: 1, nb_wrong: 0, nb_correct: 7, nb_first_guesses: 1) }
  let!(:question22) { FactoryGirl.create(:qcm_multiple, chapter: chapter2, online: true, position: 2, nb_wrong: 0, nb_correct: 0, nb_first_guesses: 0) }
  
  before do
    chapter2.prerequisites << chapter1
    user.chapters << chapter1
  end
    
  context "if the user is an admin" do
    before do
      assign(:current_user, admin)
    end
      
    it "renders the statistics correctly" do
      render template: "chapters/chapterstats"
      expect(rendered).to have_selector("h3", text: section.name)
      expect(rendered).to have_selector("th", text: "Ex. 1")
      expect(rendered).to have_selector("th", text: "Ex. 2")
      expect(rendered).to have_no_selector("th", text: "Ex. 3")
      expect(rendered).to have_link(chapter1.name, href: chapter_path(chapter1))
      expect(rendered).to have_selector("td", text: "22%")
      expect(rendered).to have_no_link("0%", href: chapter_question_path(chapter1, question11_offline.id))
      expect(rendered).to have_link("67%", href: chapter_question_path(chapter1, question12.id))
      expect(rendered).to have_link(chapter2.name, href: chapter_path(chapter2))
      expect(rendered).to have_selector("td", text: "25%")
      expect(rendered).to have_link("14%", href: chapter_question_path(chapter2, question21.id))
      expect(rendered).to have_link("0%", href: chapter_question_path(chapter2, question22.id))
      expect(rendered).to have_no_link(chapter3.name, href: chapter_path(chapter3))
    end
  end
    
  context "if the user has solved prerequisites" do
    before do
      assign(:current_user, user)
    end
    
    it "renders the statistics correctly" do
      render template: "chapters/chapterstats"
      expect(rendered).to have_selector("h3", text: section.name)
      expect(rendered).to have_selector("th", text: "Ex. 1")
      expect(rendered).to have_selector("th", text: "Ex. 2")
      expect(rendered).to have_no_selector("th", text: "Ex. 3")
      expect(rendered).to have_link(chapter1.name, href: chapter_path(chapter1))
      expect(rendered).to have_selector("td", text: "22%")
      expect(rendered).to have_no_link("0%", href: chapter_question_path(chapter1, question11_offline.id))
      expect(rendered).to have_link("67%", href: chapter_question_path(chapter1, question12.id))
      expect(rendered).to have_link(chapter2.name, href: chapter_path(chapter2))
      expect(rendered).to have_selector("td", text: "25%")
      expect(rendered).to have_link("14%", href: chapter_question_path(chapter2, question21.id))
      expect(rendered).to have_link("0%", href: chapter_question_path(chapter2, question22.id))
      expect(rendered).to have_no_link(chapter3.name, href: chapter_path(chapter3))
    end
  end
  
  context "if the user has not solved prerequisites" do
    before do
      assign(:current_user, user_bad)
    end
    
    it "renders the statistics correctly" do
      render template: "chapters/chapterstats"
      expect(rendered).to have_selector("h3", text: section.name)
      expect(rendered).to have_selector("th", text: "Ex. 1")
      expect(rendered).to have_selector("th", text: "Ex. 2")
      expect(rendered).to have_no_selector("th", text: "Ex. 3")
      expect(rendered).to have_link(chapter1.name, href: chapter_path(chapter1))
      expect(rendered).to have_selector("td", text: "22%")
      expect(rendered).to have_no_link("0%", href: chapter_question_path(chapter1, question11_offline.id))
      expect(rendered).to have_link("67%", href: chapter_question_path(chapter1, question12.id))
      expect(rendered).to have_link(chapter2.name, href: chapter_path(chapter2))
      expect(rendered).to have_selector("td", text: "25%")
      expect(rendered).to have_no_link("14%", href: chapter_question_path(chapter2, question21.id))
      expect(rendered).to have_selector("td", text: "14%")
      expect(rendered).to have_no_link("0%", href: chapter_question_path(chapter2, question22.id))
      expect(rendered).to have_selector("td", text: "0%")
      expect(rendered).to have_no_link(chapter3.name, href: chapter_path(chapter3))
    end
  end
  
  context "if the user is not signed in" do    
    it "renders the menu correctly" do
      render template: "chapters/chapterstats"
      expect(rendered).to have_selector("h3", text: section.name)
      expect(rendered).to have_selector("th", text: "Ex. 1")
      expect(rendered).to have_selector("th", text: "Ex. 2")
      expect(rendered).to have_no_selector("th", text: "Ex. 3")
      expect(rendered).to have_link(chapter1.name, href: chapter_path(chapter1))
      expect(rendered).to have_selector("td", text: "22%")
      expect(rendered).to have_no_link("0%", href: chapter_question_path(chapter1, question11_offline.id))
      expect(rendered).to have_link("67%", href: chapter_question_path(chapter1, question12.id))
      expect(rendered).to have_link(chapter2.name, href: chapter_path(chapter2))
      expect(rendered).to have_selector("td", text: "25%")
      expect(rendered).to have_no_link("14%", href: chapter_question_path(chapter2, question21.id))
      expect(rendered).to have_selector("td", text: "14%")
      expect(rendered).to have_no_link("0%", href: chapter_question_path(chapter2, question22.id))
      expect(rendered).to have_selector("td", text: "0%")
      expect(rendered).to have_no_link(chapter3.name, href: chapter_path(chapter3))
    end
  end
end
