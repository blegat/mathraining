# -*- coding: utf-8 -*-
require "spec_helper"

describe "chapters/all.html.erb", type: :view, chapter: true do

  let(:admin) { FactoryGirl.create(:admin) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:chapter) { FactoryGirl.create(:chapter, online: true) }
  let!(:theory) { FactoryGirl.create(:theory, chapter: chapter, position: 1, online: true) }
  let!(:theory_offline) { FactoryGirl.create(:theory, chapter: chapter, position: 2, online: false) }
  let!(:theory2) { FactoryGirl.create(:theory, chapter: chapter, position: 3, online: true, content: "Premier test /latextest/") }
  let!(:theory3) { FactoryGirl.create(:theory, chapter: chapter, position: 4, online: true, content: "Deuxième test /latextest/") }
  
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
      expect(rendered).to have_no_content(theory2.content) # latextest replaced by textarea
      expect(rendered).to have_selector("textarea", id: "MathInput")
      expect(rendered).to have_selector("h3", text: "3. " + theory3.title)
      expect(rendered).to have_content(theory3.content.gsub(/\/latextest\//, "")) # latextest replaced by Voir plus haut
      expect(rendered).to have_no_content(theory3.content) # latextest replaced by Voir plus haut
      expect(rendered).to have_content("Voir plus haut")
    end
  end
  
  before do
    assign(:chapter, chapter)
    assign(:section, chapter.section)
  end
  
  context "if the user is an admin" do
    before do
      assign(:signed_in, true)
      assign(:current_user, admin)
    end
    
    it "renders the online theory and nothing else" do
      render template: "chapters/all"
      expect(rendered).to have_chapter_all_content
      expect(rendered).to have_no_button("Marquer toute la théorie comme lue")
      expect(rendered).to have_no_content("Des questions ? N'hésitez pas à demander de l'aide")
      expect(response).to render_template(:partial => "chapters/_before", :locals => {active: 'all'})
      expect(response).to render_template(:partial => "chapters/_intro")
    end
  end
  
  context "if the user is not an admin" do
    before do
      assign(:signed_in, true)
      assign(:current_user, user)
    end
    
    it "renders the online theory and other stuff" do
      render template: "chapters/all"
      expect(rendered).to have_chapter_all_content
      expect(rendered).to have_button("Marquer toute la théorie comme lue")
      expect(rendered).to have_content("Des questions ? N'hésitez pas à demander de l'aide")
      expect(response).to render_template(:partial => "chapters/_before", :locals => {active: 'all'})
      expect(response).to render_template(:partial => "chapters/_intro")
    end
  end
  
  context "if the user is not signed in" do
    before do
      assign(:signed_in, false)
    end
    
    it "renders the online theory and nothing else" do
      render template: "chapters/all"
      expect(rendered).to have_chapter_all_content
      expect(rendered).to have_no_button("Marquer toute la théorie comme lue")
      expect(rendered).to have_no_content("Des questions ? N'hésitez pas à demander de l'aide")
      expect(response).to render_template(:partial => "chapters/_before", :locals => {active: 'all'})
      expect(response).to render_template(:partial => "chapters/_intro")
    end
  end
end
