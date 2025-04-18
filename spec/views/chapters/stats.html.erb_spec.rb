# -*- coding: utf-8 -*-
require "spec_helper"

describe "chapters/stats.html.erb", type: :view, chapter: true do

  subject { rendered }

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let(:user_bad) { FactoryBot.create(:user) }
  let!(:section) { FactoryBot.create(:section) }
  let!(:chapter1) { FactoryBot.create(:chapter, section: section, online: true, level: 1, position: 1, nb_tries: 9, nb_completions: 2) }
  let!(:chapter2) { FactoryBot.create(:chapter, section: section, online: true, level: 1, position: 2, nb_tries: 8, nb_completions: 2) }
  let!(:chapter3) { FactoryBot.create(:chapter, section: section, online: false, level: 2, position: 1, nb_tries: 0, nb_completions: 0) }
  let!(:question11_offline) { FactoryBot.create(:exercise, chapter: chapter1, online: false, position: 1, nb_wrong: 0, nb_correct: 0, nb_first_guesses: 0) }
  let!(:question12) { FactoryBot.create(:exercise_decimal, chapter: chapter1, online: true, position: 2, nb_wrong: 1, nb_correct: 2, nb_first_guesses: 2) }
  let!(:question21) { FactoryBot.create(:qcm, chapter: chapter2, online: true, position: 1, nb_wrong: 0, nb_correct: 7, nb_first_guesses: 1) }
  let!(:question22) { FactoryBot.create(:qcm_multiple, chapter: chapter2, online: true, position: 2, nb_wrong: 0, nb_correct: 0, nb_first_guesses: 0) }
  
  before do
    chapter2.prerequisites << chapter1
    user.chapters << chapter1
  end
    
  context "if the user is an admin" do
    before { sign_in_view(admin) }
      
    it "renders the statistics correctly" do
      render template: "chapters/stats"
      should have_selector("h3", text: section.name)
      should have_selector("th", text: "Ex. 1")
      should have_selector("th", text: "Ex. 2")
      should have_no_selector("th", text: "Ex. 3")
      should have_link(chapter1.name, href: chapter_path(chapter1))
      should have_selector("td", text: "22%")
      should have_no_link("0%", href: chapter_question_path(chapter1, question11_offline.id))
      should have_link("67%", href: chapter_question_path(chapter1, question12.id))
      should have_link(chapter2.name, href: chapter_path(chapter2))
      should have_selector("td", text: "25%")
      should have_link("14%", href: chapter_question_path(chapter2, question21.id))
      should have_link("0%", href: chapter_question_path(chapter2, question22.id))
      should have_no_link(chapter3.name, href: chapter_path(chapter3))
    end
  end
    
  context "if the user has solved prerequisites" do
    before { sign_in_view(user) }
    
    it "renders the statistics correctly" do
      render template: "chapters/stats"
      should have_selector("h3", text: section.name)
      should have_selector("th", text: "Ex. 1")
      should have_selector("th", text: "Ex. 2")
      should have_no_selector("th", text: "Ex. 3")
      should have_link(chapter1.name, href: chapter_path(chapter1))
      should have_selector("td", text: "22%")
      should have_no_link("0%", href: chapter_question_path(chapter1, question11_offline.id))
      should have_link("67%", href: chapter_question_path(chapter1, question12.id))
      should have_link(chapter2.name, href: chapter_path(chapter2))
      should have_selector("td", text: "25%")
      should have_link("14%", href: chapter_question_path(chapter2, question21.id))
      should have_link("0%", href: chapter_question_path(chapter2, question22.id))
      should have_no_link(chapter3.name, href: chapter_path(chapter3))
    end
  end
  
  context "if the user has not solved prerequisites" do
    before { sign_in_view(user_bad) }
    
    it "renders the statistics correctly" do
      render template: "chapters/stats"
      should have_selector("h3", text: section.name)
      should have_selector("th", text: "Ex. 1")
      should have_selector("th", text: "Ex. 2")
      should have_no_selector("th", text: "Ex. 3")
      should have_link(chapter1.name, href: chapter_path(chapter1))
      should have_selector("td", text: "22%")
      should have_no_link("0%", href: chapter_question_path(chapter1, question11_offline.id))
      should have_link("67%", href: chapter_question_path(chapter1, question12.id))
      should have_link(chapter2.name, href: chapter_path(chapter2))
      should have_selector("td", text: "25%")
      should have_no_link("14%", href: chapter_question_path(chapter2, question21.id))
      should have_selector("td", text: "14%")
      should have_no_link("0%", href: chapter_question_path(chapter2, question22.id))
      should have_selector("td", text: "0%")
      should have_no_link(chapter3.name, href: chapter_path(chapter3))
    end
  end
  
  context "if the user is not signed in" do    
    it "renders the menu correctly" do
      render template: "chapters/stats"
      should have_selector("h3", text: section.name)
      should have_selector("th", text: "Ex. 1")
      should have_selector("th", text: "Ex. 2")
      should have_no_selector("th", text: "Ex. 3")
      should have_link(chapter1.name, href: chapter_path(chapter1))
      should have_selector("td", text: "22%")
      should have_no_link("0%", href: chapter_question_path(chapter1, question11_offline.id))
      should have_link("67%", href: chapter_question_path(chapter1, question12.id))
      should have_link(chapter2.name, href: chapter_path(chapter2))
      should have_selector("td", text: "25%")
      should have_no_link("14%", href: chapter_question_path(chapter2, question21.id))
      should have_selector("td", text: "14%")
      should have_no_link("0%", href: chapter_question_path(chapter2, question22.id))
      should have_selector("td", text: "0%")
      should have_no_link(chapter3.name, href: chapter_path(chapter3))
    end
  end
end
