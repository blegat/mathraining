# -*- coding: utf-8 -*-
require "spec_helper"

describe "chapters/show.html.erb", type: :view, chapter: true do

  subject { rendered }

  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }
  let!(:chapter) { FactoryBot.create(:chapter, online: true) }
  let!(:chapter_prerequisite) { FactoryBot.create(:chapter, online: true) }
  let!(:chapter_prerequisite2) { FactoryBot.create(:chapter, online: true) }
  
  before do
    chapter.prerequisites << chapter_prerequisite
    chapter.prerequisites << chapter_prerequisite2
    assign(:chapter, chapter)
    assign(:section, chapter.section)
  end
  
  context "if the user is an admin" do
    before { sign_in_view(admin) }
    
    it "does not render warning about exercises" do
      render template: "chapters/show"
      should have_no_content("Pour pouvoir accéder aux exercices de ce chapitre")
      expect(response).to render_template(:partial => "chapters/_before", :locals => {active: 'show'})
      expect(response).to render_template(:partial => "chapters/_intro", :locals => {allow_edit: true})
      expect(response).to render_template(:partial => "chapters/_after")
    end
  end
  
  context "if the user is not an admin" do
    before { sign_in_view(user) }
    
    context "who didn't solve any prerequisite" do
      it "renders warning about exercises" do
        render template: "chapters/show"
        should have_content("Pour pouvoir accéder aux exercices de ce chapitre et ainsi le compléter, vous devez d'abord compléter : #{chapter_prerequisite.name} - #{chapter_prerequisite2.name}", normalize_ws: true)
        expect(response).to render_template(:partial => "chapters/_before", :locals => {active: 'show'})
        expect(response).to render_template(:partial => "chapters/_intro", :locals => {allow_edit: true})
        expect(response).to render_template(:partial => "chapters/_after")
      end
    end
    
    context "who solved one prerequisite" do
      before { user.chapters << chapter_prerequisite }
      it "renders warning about exercises" do
        render template: "chapters/show"
        should have_content("Pour pouvoir accéder aux exercices de ce chapitre et ainsi le compléter, vous devez d'abord compléter : #{chapter_prerequisite2.name}", normalize_ws: true)
      end
    end
    
    context "who solved all prerequisites" do
      before do
        user.chapters << chapter_prerequisite
        user.chapters << chapter_prerequisite2
      end
      it "does not render warning about exercises" do
        render template: "chapters/show"
        should have_no_content("Pour pouvoir accéder aux exercices de ce chapitre")
      end
    end
  end
  
  context "if the user is not signed in" do
    it "renders warning about exercises" do
      render template: "chapters/show"
      should have_content("Pour pouvoir accéder aux exercices de ce chapitre et ainsi le compléter, vous devez d'abord compléter : #{chapter_prerequisite.name} - #{chapter_prerequisite2.name}", normalize_ws: true)
      expect(response).to render_template(:partial => "chapters/_before", :locals => {active: 'show'})
      expect(response).to render_template(:partial => "chapters/_intro", :locals => {allow_edit: true})
      expect(response).to render_template(:partial => "chapters/_after")
    end
  end
end
