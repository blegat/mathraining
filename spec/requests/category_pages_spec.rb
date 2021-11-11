# -*- coding: utf-8 -*-
require "spec_helper"

describe "Category pages" do

  subject { page }

  let(:root) { FactoryGirl.create(:root) }
  let(:user) { FactoryGirl.create(:user) }
  let!(:category) { FactoryGirl.create(:category) }
  let(:newname) { "Nouveau nom" }

  describe "user" do
    before do
      sign_in user
      visit subjects_path
    end
    it { should have_no_link("Modifier les catégories") }
    
    describe "tries to create a category" do
      before { visit categories_path }
      it { should have_no_selector("h1", text: "Modifier les catégories") }
    end
  end

  describe "root" do
    before do
      sign_in root
      visit subjects_path
    end
    
    it { should have_link("Modifier les catégories") }
    
    describe "view categories" do
      before { visit categories_path }
      it { should have_selector("h1", text: "Modifier les catégories") }
      
      describe "and modifies one" do
        before do
          page.all(:fillable_field, "category[name]").first.set(newname)
          page.all(:button, "Modifier cette catégorie").first.click
        end
        specify { expect(Category.order(:id).first.name).to eq(newname) }
      end
      
      describe "and modifies one with bad name" do
        before do
          page.all(:fillable_field, "category[name]").first.set("")
          page.all(:button, "Modifier cette catégorie").first.click
        end
        it { should have_selector("div", text: "Une erreur est survenue.") }
        specify { expect(Category.order(:id).first.name).to_not eq("") }
      end
      
      describe "and adds one with good name" do
        before do
          page.all(:fillable_field, "category[name]").last.set(newname)
          click_button "Ajouter cette catégorie"
        end
        specify { expect(Category.order(:id).last.name).to eq(newname) }
      end
      
      describe "and adds one with bad name" do
        before do
          page.all(:fillable_field, "category[name]").last.set("")
          click_button "Ajouter cette catégorie"
        end
        it { should have_selector("div", text: "Une erreur est survenue.") }
        specify { expect(Category.order(:id).last.name).to_not eq("") }
      end
      
      describe "and deletes one" do
        specify { expect { click_link("Supprimer cette catégorie") }.to change(Category, :count).by(-1) }
      end
    end
  end
end
