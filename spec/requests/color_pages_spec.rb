# -*- coding: utf-8 -*-
require "spec_helper"

describe "Color pages" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:color) { FactoryGirl.create(:color) }
  let(:newtitle) { "Nouveau titre" }
  let(:newcontent) { "Nouveau contenu" }

  describe "admin" do
    before { sign_in admin }
    before { visit colors_path }
    it { should_not have_selector("h1", text: "Niveaux et couleurs") }
  end

  describe "root" do
    before { sign_in root }
    before { visit colors_path }
    
    it { should have_selector("h1", text: "Niveaux et couleurs") }
    
    describe "creates a color" do
      describe "with good information" do
        before do
          find_by_id('pt_add').set(20)
          find_by_id('name_add').set("new_name")
          find_by_id('femininename_add').set("new_feminine_name")
          find_by_id('color_add').set("#AABBCC")
          find_by_id('font_color_add').set("#BBCCDD")
          find_by_id('button_add').click
        end
        specify { expect(Color.order(:id).last.name).to eq("new_name") }
        specify { expect(Color.order(:id).last.color).to eq("#AABBCC") }
      end
      describe "with wrong information" do
        before do
          find_by_id('pt_add').set(20)
          find_by_id('name_add').set("new_name")
          find_by_id('femininename_add').set("new_feminine_name")
          find_by_id('color_add').set("#AABBC") # Too short
          find_by_id('font_color_add').set("#BBCCDD")
          find_by_id('button_add').click
        end
        it { should have_content("erreur") }
        it { should have_selector("h1", text: "Niveaux et couleurs") }
        specify { expect(Color.order(:id).last.name).to_not eq("new_name") }
      end
    end
    
    describe "edits a color" do
      describe "with good information" do
        before do
          find_by_id('pt_edit1').set(20)
          find_by_id('name_edit1').set("new_name")
          find_by_id('femininename_edit1').set("new_feminine_name")
          find_by_id('color_edit1').set("#AABBCC")
          find_by_id('font_color_edit1').set("#BBCCDD")
          find_by_id('button_edit1').click
          color.reload
        end
        specify { expect(color.name).to eq("new_name") }
        specify { expect(color.color).to eq("#AABBCC") }
      end
      describe "with wrong information" do
        before do
          find_by_id('pt_edit1').set(20)
          find_by_id('name_edit1').set("new_name")
          find_by_id('femininename_edit1').set("new_feminine_name")
          find_by_id('color_edit1').set("#AABBCC")
          find_by_id('font_color_edit1').set("#BBCCD") # Too short
          find_by_id('button_edit1').click
          color.reload
        end
        it { should have_content("erreur") }
        it { should have_selector("h1", text: "Niveaux et couleurs") }
        specify { expect(color.name).to_not eq("new_name") }
      end
    end
    
    describe "deletes a color" do
      specify { expect { click_link("Supprimer") }.to change(Color, :count).by(-1) }
    end
  end
end
