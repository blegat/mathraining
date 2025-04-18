# -*- coding: utf-8 -*-
require "spec_helper"

describe "sections/show.html.erb", type: :view, section: true do

  subject { rendered }

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  
  let!(:section) { FactoryBot.create(:section) }
  
  let!(:chapter1) { FactoryBot.create(:chapter, section: section, online: true, level: 1, position: 1) }
  let!(:theory11) { FactoryBot.create(:theory, chapter: chapter1, online: true, position: 1) }
  let!(:theory12) { FactoryBot.create(:theory, chapter: chapter1, online: true, position: 2) }
  let!(:theory13_offline) { FactoryBot.create(:theory, chapter: chapter1, online: false, position: 3) }
  let!(:question11) { FactoryBot.create(:exercise, chapter: chapter1, online: true, position: 1) }
  let!(:question12) { FactoryBot.create(:exercise, chapter: chapter1, online: true, position: 2) }
  let!(:question13_offline) { FactoryBot.create(:exercise, chapter: chapter1, online: false, position: 3) }
  let!(:question14) { FactoryBot.create(:exercise, chapter: chapter1, online: true, position: 4) }
  
  let!(:chapter2) { FactoryBot.create(:chapter, section: section, online: true, level: 1, position: 2) }
  let!(:theory21) { FactoryBot.create(:theory, chapter: chapter2, online: true, position: 1) }
  let!(:theory22_offline) { FactoryBot.create(:theory, chapter: chapter2, online: false, position: 2) }
  let!(:question21) { FactoryBot.create(:exercise, chapter: chapter2, online: true, position: 1) }
  let!(:question22_offline) { FactoryBot.create(:exercise, chapter: chapter2, online: false, position: 2) }
  
  let!(:chapter3) { FactoryBot.create(:chapter, section: section, online: true, level: 1, position: 3) }
  let!(:theory31) { FactoryBot.create(:theory, chapter: chapter3, online: true, position: 1) }
  let!(:question31) { FactoryBot.create(:exercise, chapter: chapter3, online: true, position: 1) }
  
  let!(:chapter4) { FactoryBot.create(:chapter, section: section, online: true, level: 1, position: 4) }
  let!(:question41) { FactoryBot.create(:exercise, chapter: chapter4, online: true, position: 1) }
  
  let!(:chapter5_offline) { FactoryBot.create(:chapter, section: section, online: false, level: 1, position: 5) }
  let!(:theory51_offline) { FactoryBot.create(:theory, chapter: chapter5_offline, online: false) }
  let!(:question51_offline) { FactoryBot.create(:question, chapter: chapter5_offline, online: false) }
  
  before do
    chapter2.prerequisites << chapter1
    chapter3.prerequisites << chapter1
    chapter4.prerequisites << chapter2
    chapter4.prerequisites << chapter3
    assign(:section, section)
  end
  
  describe "visitor" do
  
    describe "for a non-fondation section" do
      it do
        render template: "sections/show"
        
        should have_selector("h1", text: section.name)
        should have_content(section.description)
        should have_no_link("Modifier l'introduction")
        
        should have_selector("table", id: "chapter#{chapter1.id}", class: "yellowy", text: chapter1.name)
        should have_link(theory11.title, href: chapter_theory_path(chapter1, theory11))
        should have_link(theory12.title, href: chapter_theory_path(chapter1, theory12))
        should have_no_link(theory13_offline.title)
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter1, question11))
        should have_link(class: "btn-ld-light-dark", text: "2", href: chapter_question_path(chapter1, question12))
        should have_no_link(class: "btn-ld-light-dark", href: chapter_question_path(chapter1, question13_offline))
        should have_link(class: "btn-ld-light-dark", text: "3", href: chapter_question_path(chapter1, question14))
        
        should have_selector("table", id: "chapter#{chapter2.id}", class: "greyy", text: chapter2.name)
        should have_selector("table", id: "chapter#{chapter2.id}", text: "Pour pouvoir accéder aux exercices de ce chapitre, vous devez d'abord compléter :")
        should have_selector("table", id: "chapter#{chapter2.id}", text: chapter1.name)
        should have_link(theory21.title, href: chapter_theory_path(chapter2, theory21))
        should have_no_link(theory22_offline.title)
        should have_button(class: "disabled", id: "disabled-question-#{question21.id}", text: "1")
        should have_no_button(class: "disabled", id: "disabled-question-#{question22_offline.id}", text: "2")
        
        should have_selector("table", id: "chapter#{chapter3.id}", class: "greyy", text: chapter3.name)
        should have_selector("table", id: "chapter#{chapter3.id}", text: "Pour pouvoir accéder aux exercices de ce chapitre, vous devez d'abord compléter :")
        should have_selector("table", id: "chapter#{chapter3.id}", text: chapter1.name)
        should have_link(theory31.title, href: chapter_theory_path(chapter3, theory31))
        should have_button(class: "disabled", id: "disabled-question-#{question31.id}", text: "1")
        
        should have_selector("table", id: "chapter#{chapter4.id}", class: "greyy", text: chapter4.name)
        should have_selector("table", id: "chapter#{chapter4.id}", text: "Pour pouvoir accéder aux exercices de ce chapitre, vous devez d'abord compléter :")
        should have_selector("table", id: "chapter#{chapter4.id}", text: chapter2.name)
        should have_selector("table", id: "chapter#{chapter4.id}", text: chapter3.name)
        should have_button(class: "disabled", id: "disabled-question-#{question41.id}", text: "1")
        
        should have_no_selector("table", id: "chapter#{chapter5_offline.id}", text: chapter5_offline.name)
        should have_no_link(theory51_offline.title)
        
        should have_no_link("Ajouter un chapitre")
      end
    end
    
    describe "for a fondation section" do
      before do
        section.update_attribute(:fondation, true)
      end
      it do
        render template: "sections/show"
        
        should have_selector("h1", text: section.name)
        should have_content(section.description)
        should have_no_link("Modifier l'introduction")
        
        should have_selector("table", id: "chapter#{chapter1.id}", class: "yellowy", text: chapter1.name)
        should have_link(theory11.title, href: chapter_theory_path(chapter1, theory11))
        should have_link(theory12.title, href: chapter_theory_path(chapter1, theory12))
        should have_no_link(theory13_offline.title)
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter1, question11))
        should have_link(class: "btn-ld-light-dark", text: "2", href: chapter_question_path(chapter1, question12))
        should have_no_link(class: "btn-ld-light-dark", href: chapter_question_path(chapter1, question13_offline))
        should have_link(class: "btn-ld-light-dark", text: "3", href: chapter_question_path(chapter1, question14))
        
        should have_selector("table", id: "chapter#{chapter2.id}", class: "yellowy", text: chapter2.name)
        should have_link(theory21.title, href: chapter_theory_path(chapter2, theory21))
        should have_no_link(theory22_offline.title)
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter2, question21))
        should have_no_link(href: chapter_question_path(chapter2, question22_offline))
        
        should have_selector("table", id: "chapter#{chapter3.id}", class: "yellowy", text: chapter3.name)
        should have_link(theory31.title, href: chapter_theory_path(chapter3, theory31))
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter3, question31))
        
        should have_selector("table", id: "chapter#{chapter4.id}", class: "yellowy", text: chapter4.name)
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter4, question41))
        
        should have_no_selector("table", id: "chapter#{chapter5_offline.id}", text: chapter5_offline.name)
        should have_no_link(theory51_offline.title)
        
        should have_no_link("Ajouter un chapitre")
      end
    end
  end
  
  describe "user" do
    before { sign_in_view user }
    
    describe "having completed no chapter" do
      before do
        FactoryBot.create(:solvedquestion, user: user, question: question11)
        FactoryBot.create(:unsolvedquestion, user: user, question: question12)
        user.theories << theory11
      end
      it do
        render template: "sections/show"
        
        should have_selector("h1", text: section.name)
        should have_content(section.description)
        should have_no_link("Modifier l'introduction")
        
        should have_selector("table", id: "chapter#{chapter1.id}", class: "yellowy", text: chapter1.name)
        should have_link(theory11.title, href: chapter_theory_path(chapter1, theory11))
        should have_css("img[id=V-#{theory11.id}]")
        should have_link(theory12.title, href: chapter_theory_path(chapter1, theory12))
        should have_no_css("img[id=V-#{theory12.id}]")
        should have_no_link(theory13_offline.title)
        should have_link(class: "btn-success", text: "1", href: chapter_question_path(chapter1, question11))
        should have_link(class: "btn-danger", text: "2", href: chapter_question_path(chapter1, question12))
        should have_no_link(href: chapter_question_path(chapter1, question13_offline))
        should have_link(class: "btn-ld-light-dark", text: "3", href: chapter_question_path(chapter1, question14))
        
        should have_selector("table", id: "chapter#{chapter2.id}", class: "greyy", text: chapter2.name)
        should have_selector("table", id: "chapter#{chapter2.id}", text: "Pour pouvoir accéder aux exercices de ce chapitre, vous devez d'abord compléter :")
        should have_selector("table", id: "chapter#{chapter2.id}", text: chapter1.name)
        should have_link(theory21.title, href: chapter_theory_path(chapter2, theory21))
        should have_no_link(theory22_offline.title)
        should have_button(class: "disabled", id: "disabled-question-#{question21.id}", text: "1")
        should have_no_button(class: "disabled", id: "disabled-question-#{question22_offline.id}", text: "2")
        
        should have_selector("table", id: "chapter#{chapter3.id}", class: "greyy", text: chapter3.name)
        should have_selector("table", id: "chapter#{chapter3.id}", text: "Pour pouvoir accéder aux exercices de ce chapitre, vous devez d'abord compléter :")
        should have_selector("table", id: "chapter#{chapter3.id}", text: chapter1.name)
        should have_link(theory31.title, href: chapter_theory_path(chapter3, theory31))
        should have_button(class: "disabled", id: "disabled-question-#{question31.id}", text: "1")
        
        should have_selector("table", id: "chapter#{chapter4.id}", class: "greyy", text: chapter4.name)
        should have_selector("table", id: "chapter#{chapter4.id}", text: "Pour pouvoir accéder aux exercices de ce chapitre, vous devez d'abord compléter :")
        should have_selector("table", id: "chapter#{chapter4.id}", text: chapter2.name)
        should have_selector("table", id: "chapter#{chapter4.id}", text: chapter3.name)
        should have_button(class: "disabled", id: "disabled-question-#{question41.id}", text: "1")
        
        should have_no_selector("table", id: "chapter#{chapter5_offline.id}", text: chapter5_offline.name)
        should have_no_link(theory51_offline.title)
        
        should have_no_link("Ajouter un chapitre")
      end
    end
    
    describe "having completed two chapters" do
      before do
        FactoryBot.create(:solvedquestion, user: user, question: question11)
        FactoryBot.create(:solvedquestion, user: user, question: question12)
        FactoryBot.create(:solvedquestion, user: user, question: question14)
        FactoryBot.create(:solvedquestion, user: user, question: question21)
        user.theories << theory11
        user.theories << theory12
        user.chapters << chapter1
        user.chapters << chapter2
      end
      it do
        render template: "sections/show"
        
        should have_selector("h1", text: section.name)
        should have_content(section.description)
        should have_no_link("Modifier l'introduction")
        
        should have_selector("table", id: "chapter#{chapter1.id}", class: "greeny", text: chapter1.name)
        should have_link(theory11.title, href: chapter_theory_path(chapter1, theory11))
        should have_css("img[id=V-#{theory11.id}]")
        should have_link(theory12.title, href: chapter_theory_path(chapter1, theory12))
        should have_css("img[id=V-#{theory12.id}]")
        should have_no_link(theory13_offline.title)
        should have_link(class: "btn-success", text: "1", href: chapter_question_path(chapter1, question11))
        should have_link(class: "btn-success", text: "2", href: chapter_question_path(chapter1, question12))
        should have_no_link(href: chapter_question_path(chapter1, question13_offline))
        should have_link(class: "btn-success", text: "3", href: chapter_question_path(chapter1, question14))
        
        should have_selector("table", id: "chapter#{chapter2.id}", class: "greeny", text: chapter2.name)
        should have_link(theory21.title, href: chapter_theory_path(chapter2, theory21))
        should have_no_link(theory22_offline.title)
        should have_link(class: "btn-success", text: "1", href: chapter_question_path(chapter2, question21))
        
        should have_selector("table", id: "chapter#{chapter3.id}", class: "yellowy", text: chapter3.name)
        should have_link(theory31.title, href: chapter_theory_path(chapter3, theory31))
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter3, question31))
        
        should have_selector("table", id: "chapter#{chapter4.id}", class: "greyy", text: chapter4.name)
        should have_selector("table", id: "chapter#{chapter4.id}", text: "Pour pouvoir accéder aux exercices de ce chapitre, vous devez d'abord compléter :")
        should have_selector("table", id: "chapter#{chapter4.id}", text: chapter3.name)
        should have_button(class: "disabled", id: "disabled-question-#{question41.id}", text: "1")
        
        should have_no_selector("table", id: "chapter#{chapter5_offline.id}", text: chapter5_offline.name)
        should have_no_link(theory51_offline.title)
        
        should have_no_link("Ajouter un chapitre")
      end
    end
    
    describe "having completed one chapter for a fondation section" do
      before do
        section.update_attribute(:fondation, true)
        FactoryBot.create(:solvedquestion, user: user, question: question11)
        FactoryBot.create(:solvedquestion, user: user, question: question12)
        FactoryBot.create(:solvedquestion, user: user, question: question14)
        user.theories << theory11
        user.theories << theory12
        #user.chapters << chapter1 # We don't remember completed chapters for fondation section
      end
      it do
        render template: "sections/show"
        
        should have_selector("h1", text: section.name)
        should have_content(section.description)
        should have_no_link("Modifier l'introduction")
        
        should have_selector("table", id: "chapter#{chapter1.id}", class: "yellowy", text: chapter1.name)
        should have_link(theory11.title, href: chapter_theory_path(chapter1, theory11))
        should have_css("img[id=V-#{theory11.id}]")
        should have_link(theory12.title, href: chapter_theory_path(chapter1, theory12))
        should have_css("img[id=V-#{theory12.id}]")
        should have_no_link(theory13_offline.title)
        should have_link(class: "btn-success", text: "1", href: chapter_question_path(chapter1, question11))
        should have_link(class: "btn-success", text: "2", href: chapter_question_path(chapter1, question12))
        should have_no_link(href: chapter_question_path(chapter1, question13_offline))
        should have_link(class: "btn-success", text: "3", href: chapter_question_path(chapter1, question14))
        
        should have_selector("table", id: "chapter#{chapter2.id}", class: "yellowy", text: chapter2.name)
        should have_link(theory21.title, href: chapter_theory_path(chapter2, theory21))
        should have_no_link(theory22_offline.title)
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter2, question21))
        
        should have_selector("table", id: "chapter#{chapter3.id}", class: "yellowy", text: chapter3.name)
        should have_link(theory31.title, href: chapter_theory_path(chapter3, theory31))
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter3, question31))
        
        should have_selector("table", id: "chapter#{chapter4.id}", class: "yellowy", text: chapter4.name)
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter4, question41))
        
        should have_no_selector("table", id: "chapter#{chapter5_offline.id}", text: chapter5_offline.name)
        should have_no_link(theory51_offline.title)
        
        should have_no_link("Ajouter un chapitre")
      end
    end
  end
  
  describe "admin" do
    before { sign_in_view admin }
    
    describe "for a non-fondation section" do
      it do
        render template: "sections/show"
        
        should have_selector("h1", text: section.name)
        should have_content(section.description)
        should have_link("Modifier l'introduction")
        
        should have_selector("table", id: "chapter#{chapter1.id}", class: "yellowy", text: chapter1.name)
        should have_link(theory11.title, href: chapter_theory_path(chapter1, theory11))
        should have_link(theory12.title, href: chapter_theory_path(chapter1, theory12))
        should have_no_link(theory13_offline.title) # Even for admin there is no link to an offline theory inside an online chapter
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter1, question11))
        should have_link(class: "btn-ld-light-dark", text: "2", href: chapter_question_path(chapter1, question12))
        should have_link(class: "btn-warning", text: "!", href: chapter_question_path(chapter1, question13_offline))
        should have_link(class: "btn-ld-light-dark", text: "3", href: chapter_question_path(chapter1, question14))
        
        should have_selector("table", id: "chapter#{chapter2.id}", class: "yellowy", text: chapter2.name)
        should have_link(theory21.title, href: chapter_theory_path(chapter2, theory21))
        should have_no_link(theory22_offline.title) # Even for admin there is no link to an offline theory inside an online chapter
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter2, question21))
        should have_link(class: "btn-warning", text: "!", href: chapter_question_path(chapter2, question22_offline))
        
        should have_selector("table", id: "chapter#{chapter3.id}", class: "yellowy", text: chapter3.name)
        should have_link(theory31.title, href: chapter_theory_path(chapter3, theory31))
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter3, question31))
        
        should have_selector("table", id: "chapter#{chapter4.id}", class: "yellowy", text: chapter4.name)
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter4, question41))
        
        should have_selector("table", id: "chapter#{chapter5_offline.id}", class: "orangey", text: chapter5_offline.name)
        should have_link(theory51_offline.title, href: chapter_theory_path(chapter5_offline, theory51_offline))
        should have_link(class: "btn-warning", text: "!", href: chapter_question_path(chapter5_offline, question51_offline))
        
        should have_link("Ajouter un chapitre")
      end
    end
    
    describe "for a fondation section" do
      before { section.update_attribute(:fondation, true) }
      it do
        render template: "sections/show"
        
        should have_selector("h1", text: section.name)
        should have_content(section.description)
        should have_link("Modifier l'introduction")
        
        should have_selector("table", id: "chapter#{chapter1.id}", class: "yellowy", text: chapter1.name)
        should have_link(theory11.title, href: chapter_theory_path(chapter1, theory11))
        should have_link(theory12.title, href: chapter_theory_path(chapter1, theory12))
        should have_no_link(theory13_offline.title) # Even for admin there is no link to an offline theory inside an online chapter
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter1, question11))
        should have_link(class: "btn-ld-light-dark", text: "2", href: chapter_question_path(chapter1, question12))
        should have_link(class: "btn-warning", text: "!", href: chapter_question_path(chapter1, question13_offline))
        should have_link(class: "btn-ld-light-dark", text: "3", href: chapter_question_path(chapter1, question14))
        
        should have_selector("table", id: "chapter#{chapter2.id}", class: "yellowy", text: chapter2.name)
        should have_link(theory21.title, href: chapter_theory_path(chapter2, theory21))
        should have_no_link(theory22_offline.title) # Even for admin there is no link to an offline theory inside an online chapter
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter2, question21))
        should have_link(class: "btn-warning", text: "!", href: chapter_question_path(chapter2, question22_offline))
        
        should have_selector("table", id: "chapter#{chapter3.id}", class: "yellowy", text: chapter3.name)
        should have_link(theory31.title, href: chapter_theory_path(chapter3, theory31))
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter3, question31))
        
        should have_selector("table", id: "chapter#{chapter4.id}", class: "yellowy", text: chapter4.name)
        should have_link(class: "btn-ld-light-dark", text: "1", href: chapter_question_path(chapter4, question41))
        
        should have_selector("table", id: "chapter#{chapter5_offline.id}", class: "orangey", text: chapter5_offline.name)
        should have_link(theory51_offline.title, href: chapter_theory_path(chapter5_offline, theory51_offline))
        should have_link(class: "btn-warning", text: "!", href: chapter_question_path(chapter5_offline, question51_offline))
        
        should have_link("Ajouter un chapitre")
      end
    end
  end
end
