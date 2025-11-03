# -*- coding: utf-8 -*-
require "spec_helper"

describe "chapters/all.html.erb", type: :view, chapter: true do

  subject { rendered }

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let!(:chapter) { FactoryBot.create(:chapter, online: true) }
  let!(:theory) { FactoryBot.create(:theory, chapter: chapter, position: 1, online: true) }
  let!(:theory_offline) { FactoryBot.create(:theory, chapter: chapter, position: 2, online: false) }
  let!(:theory2) { FactoryBot.create(:theory, chapter: chapter, position: 3, online: true, content: "Premier test /latextest/") }
  let!(:theory3) { FactoryBot.create(:theory, chapter: chapter, position: 4, online: true, content: "Deuxième test /latextest/") }
  
  RSpec::Matchers.define :have_chapter_all_content do
    match do |rendered|
      expect(rendered).to have_content(chapter.description)
      expect(rendered).to have_content(chapter.author)
      expect(rendered).to have_selector("h3", text: "1. " + theory.title)
      expect(rendered).to have_content(theory.content)
      expect(rendered).to have_no_selector("h3", text: theory_offline.title)
      expect(rendered).to have_no_content(theory_offline.content)
      expect(rendered).to have_selector("h3", text: "2. " + theory2.title)
      expect(rendered).to have_content(theory2.content.gsub(/\/latextest\//, "")) # latextest replaced by textarea
      expect(rendered).to have_no_content(theory2.content) # latextest replaced by textarea with key 1
      expect(rendered).to have_selector("textarea", id: "MathInput1")
      expect(rendered).to have_selector("h3", text: "3. " + theory3.title)
      expect(rendered).to have_content(theory3.content.gsub(/\/latextest\//, "")) # latextest replaced by Voir plus haut
      expect(rendered).to have_no_content(theory3.content) # latextest replaced by textarea with key 2
      expect(rendered).to have_selector("textarea", id: "MathInput2")
    end
  end
  
  before do
    assign(:chapter, chapter)
    assign(:section, chapter.section)
  end
  
  context "if the user is an admin" do
    before { sign_in_view(admin) }
    
    it "renders the online theory and nothing else" do
      render template: "chapters/all"
      should have_chapter_all_content
      should have_no_link("Marquer toute la théorie comme lue")
      should have_no_content("Des questions ? N'hésitez pas à demander de l'aide")
      expect(response).to render_template(:partial => "chapters/_before", :locals => {active: 'all'})
      expect(response).to render_template(:partial => "chapters/_intro")
    end
  end
  
  context "if the user is not an admin" do
    before { sign_in_view(user) }
    
    it "renders the online theory and other stuff" do
      render template: "chapters/all"
      should have_chapter_all_content
      should have_link("Marquer toute la théorie comme lue")
      should have_content("Des questions ? N'hésitez pas à demander de l'aide")
      expect(response).to render_template(:partial => "chapters/_before", :locals => {active: 'all'})
      expect(response).to render_template(:partial => "chapters/_intro")
    end
  end
  
  context "if the user is not signed in" do    
    it "renders the online theory and nothing else" do
      render template: "chapters/all"
      should have_chapter_all_content
      should have_no_link("Marquer toute la théorie comme lue")
      should have_no_content("Des questions ? N'hésitez pas à demander de l'aide")
      expect(response).to render_template(:partial => "chapters/_before", :locals => {active: 'all'})
      expect(response).to render_template(:partial => "chapters/_intro")
    end
  end
end
