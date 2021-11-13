# -*- coding: utf-8 -*-
require "spec_helper"

describe "Actuality pages" do

  subject { page }

  let(:user) { FactoryGirl.create(:user) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:admin2) { FactoryGirl.create(:admin) }
  
  let(:image_folder) { "./spec/images/" }
  let(:good_image) { "mathraining.png" }
  
  describe "user" do
    before { sign_in user }
    
    describe "tries to visit pictures page" do
      before { visit pictures_path }
      it { should have_content(error_access_refused) }
    end
    
    describe "tries to upload a new picture" do
      before { visit new_picture_path }
      it { should have_content(error_access_refused) }
    end
  end

  describe "admin" do
    before { sign_in admin }
    
    describe "visits pictures page" do
      before { visit pictures_path }
      it do
        should have_selector("h1", text: "Vos images")
        should have_link("Uploader une nouvelle image", href: new_picture_path)
      end
    end
    
    describe "visits a non-existent picture" do
      before { visit picture_path(1) }
      it { should have_content(error_access_refused) }
    end
    
    describe "visits new picture page" do
      before { visit new_picture_path }
      it { should have_selector("h1", text: "Uploader une nouvelle image") }
      
      describe "and try to upload an empty picture" do
        before { click_button "Uploader" }
        specify { expect(Picture.count).to eq(0) }
        it { should have_content("Image doit être rempli(e)") }
      end
      
      describe "and upload a new picture" do
        before do
          attach_file("picture_image", File.absolute_path(image_folder + good_image))
          click_button "Uploader"
        end
        specify do
          expect(Picture.count).to eq(1)
          expect(Picture.last.image.blob.filename).to eq(good_image)
        end
        it do
          should have_content("Image ajoutée.")
          should have_selector("h1", text: "Récupérer un url")
          should have_xpath("//img[contains(@src, '#{good_image}')]")
          should have_content(rails_blob_url(Picture.last.image, :only_path => true))
        end
        
        let!(:picture) { Picture.last }
        
        describe "and visits pictures page" do
          before { visit pictures_path }
          it do
            should have_selector("h1", text: "Vos images")
            should have_xpath("//img[contains(@src, '#{good_image}')]")
            should have_link("Supprimer cette image", href: picture_path(picture))
          end
          specify { expect { click_link("Supprimer cette image", href: picture_path(picture)) }.to change(Picture, :count).by(-1) }
        end
        
        describe "and another admin tries to see it" do
          before do
            sign_out
            sign_in admin2
            visit picture_path(picture)
          end
          it { should have_content(error_access_refused) }
        end
      end
    end
  end
end
