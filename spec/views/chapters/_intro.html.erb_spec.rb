# -*- coding: utf-8 -*-
require "spec_helper"

describe "chapters/_intro.html.erb", type: :view, chapter: true do

  subject { rendered }

  let(:root) { FactoryBot.create(:root) }
  let(:user) { FactoryBot.create(:user) }
  let(:section_fondation) { FactoryBot.create(:section, fondation: true) }
  let(:chapter1) { FactoryBot.create(:chapter, section: section_fondation, level: 1, position: 1, author: nil, publication_date: nil, online: false) }
  let(:chapter2) { FactoryBot.create(:chapter, section: section_fondation, level: 1, position: 2, author: "Jean Dupont", publication_date: Date.new(2023, 11, 10), online: true, submission_prerequisite: true) }
  let(:chapter3) { FactoryBot.create(:chapter, section: section_fondation, level: 1, position: 3, author: "Jean Flabour", publication_date: nil, online: true) }
  
  context "if the user is a root" do
    before { sign_in_view(root) }
    
    context "and the chapter is very empty" do
      before do
        assign(:section, chapter1.section)
        assign(:chapter, chapter1)
      end
      
      it "renders correctly when allow_edit = false" do
        render partial: "chapters/intro"
        should have_content("Aucun prérequis.")
        should have_no_link("Ajouter un prérequis")
        should have_content(chapter1.description)
        should have_no_content("Ce chapitre a été créé")
        should have_no_link("Modifier ce chapitre")
      end
      
      it "renders correctly when allow_edit = true" do
        render partial: "chapters/intro", locals: {allow_edit: true}
        should have_content("Aucun prérequis.")
        should have_link("Ajouter un prérequis")
        should have_link("Modifier ce chapitre")
        should have_no_content("Déplacer vers le")
        should have_link("Supprimer ce chapitre")
        should have_no_content("Ce chapitre est un prérequis pour écrire une soumission à un problème")
        should have_link("Marquer comme prérequis aux soumissions")
        should have_no_link("Marquer comme non prérequis aux soumissions")
      end
    end
    
    context "and the chapter is very full" do
      let!(:chapter_prerequisite) { FactoryBot.create(:chapter, section: chapter2.section, level: chapter2.level, position: chapter2.position - 1) }
      
      before do
        chapter2.prerequisites << chapter_prerequisite
        assign(:section, chapter2.section)
        assign(:chapter, chapter2)
      end
      
      it "renders correctly when allow_edit = false" do
        render partial: "chapters/intro"
        should have_link(chapter_prerequisite.name, href: chapter_path(chapter_prerequisite))
        should have_no_link("Ajouter un prérequis")
        should have_content(chapter2.description)
        should have_content("écrit par #{chapter2.author} et")
        should have_content("mis en ligne le #{ write_date_only(chapter2.publication_date) }.")
        should have_no_link("Modifier ce chapitre")
      end
      
      it "renders correctly when allow_edit = true" do
        render partial: "chapters/intro", locals: {allow_edit: true}
        should have_no_link("Ajouter un prérequis") # because online
        should have_link("Modifier ce chapitre")
        should have_content("Déplacer vers le")
        should have_link("haut", href: order_chapter_path(chapter2, :new_position => chapter_prerequisite.position))
        should have_no_link("bas")
        should have_no_link("Supprimer ce chapitre") # because online
        should have_content("Ce chapitre est un prérequis pour écrire une soumission à un problème")
        should have_no_link("Marquer comme prérequis aux soumissions")
        should have_link("Marquer comme non prérequis aux soumissions")
      end
    end
  end
  
  context "if the user is not an admin" do
    before { sign_in_view(user) }
    
    context "and the chapter is normal" do
      before { assign(:chapter, chapter3) }
    
      it "renders correctly when allow_edit = true" do
        render partial: "chapters/intro", locals: {allow_edit: true} # should still not be able to edit
        should have_content("Aucun prérequis.")
        should have_no_link("Ajouter un prérequis")
        should have_content("écrit par #{chapter3.author}.")
        should have_no_content("mis en ligne")
        should have_content(chapter3.description)
        should have_no_link("Modifier ce chapitre")
      end
    end
  end
end
