# -*- coding: utf-8 -*-
require "spec_helper"

describe "Color pages", color: true do

  subject { page }

  let(:root) { FactoryBot.create(:root) }
  let(:admin) { FactoryBot.create(:admin) }
  let!(:color) { FactoryBot.create(:color) }
  let(:newtitle) { "Nouveau titre" }
  let(:newcontent) { "Nouveau contenu" }

  describe "root" do
    before do
      Color.create_defaults
      sign_in root
      visit colors_path
    end
    
    it { should have_selector("h1", text: "Niveaux et couleurs") }
    
    describe "creates a color" do
      describe "with good information" do
        before do
          find_by_id('pt_add').set(20)
          find_by_id('name_add').set("new_name")
          find_by_id('femininename_add').set("new_feminine_name")
          find_by_id('color_add').set("#AABBCC")
          find_by_id('dark_color_add').set("#BBCCDD")
          find_by_id('button_add').click
        end
        specify do
          expect(Color.order(:id).last.name).to eq("new_name")
          expect(Color.order(:id).last.color).to eq("#AABBCC")
          expect(Color.order(:id).last.dark_color).to eq("#BBCCDD")
        end
      end
      
      describe "with wrong information" do
        before do
          find_by_id('pt_add').set(20)
          find_by_id('name_add').set("new_name")
          find_by_id('femininename_add').set("new_feminine_name")
          find_by_id('color_add').set("#AABBC") # Too short
           find_by_id('dark_color_add').set("#BBCCDD")
          find_by_id('button_add').click
        end
        specify do
          expect(page).to have_error_message("erreur")
          expect(page).to have_selector("h1", text: "Niveaux et couleurs")
          expect(Color.order(:id).last.name).to_not eq("new_name")
        end
      end
    end
    
    describe "edits a color" do
      describe "with good information" do
        before do
          find_by_id('pt_edit11').set(20)
          find_by_id('name_edit11').set("new_name")
          find_by_id('femininename_edit11').set("new_feminine_name")
          find_by_id('color_edit11').set("#AABBCC")
          find_by_id('dark_color_edit11').set("#BBCCDD")
          find_by_id('button_edit11').click
          color.reload
        end
        specify do
          expect(color.name).to eq("new_name")
          expect(color.color).to eq("#AABBCC")
          expect(color.dark_color).to eq("#BBCCDD")
        end
      end
      
      describe "with wrong information" do
        before do
          find_by_id('pt_edit11').set(20)
          find_by_id('name_edit11').set("new_name")
          find_by_id('femininename_edit11').set("new_feminine_name")
          find_by_id('color_edit11').set("#AABBCC")
          find_by_id('dark_color_edit11').set("#BBCCD") # Too short
          find_by_id('button_edit11').click
          color.reload
        end
        specify do
          expect(page).to have_error_message("erreur")
          expect(page).to have_selector("h1", text: "Niveaux et couleurs")
          expect(color.name).to_not eq("new_name")
        end
      end
    end
    
    describe "deletes a color" do
      specify { expect { find_by_id('link_delete11').click }.to change(Color, :count).by(-1) }
    end
  end
end
