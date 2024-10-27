# -*- coding: utf-8 -*-
require "spec_helper"

describe "Picture pages", picture: true do

  subject { page }

  let(:admin) { FactoryGirl.create(:admin) }
  let(:admin2) { FactoryGirl.create(:admin) }
  
  let(:image_folder) { "./spec/attachments/" }
  let(:good_image) { "mathraining.png" }

  describe "admin" do
    before { sign_in admin }
    
    describe "visits pictures page" do
      before { visit pictures_path }
      it do
        should have_selector("h1", text: "Vos images")
        should have_button("Uploader une nouvelle image")
      end
    end
    
    describe "visits new picture page" do
      before { visit new_picture_path }
      it { should have_selector("h1", text: "Uploader une nouvelle image") }
      
      describe "and try to upload an empty picture" do
        before { click_button "Uploader" }
        specify do
          expect(Picture.count).to eq(0)
          expect(page).to have_error_message("Image doit être rempli(e)")
        end
      end
      
      describe "and upload a new picture" do
        before do
          attach_file("picture_image", File.absolute_path(image_folder + good_image))
          click_button "Uploader"
        end
        specify do
          expect(Picture.count).to eq(1)
          expect(Picture.last.image.blob.filename).to eq(good_image)
          expect(page).to have_success_message("Image ajoutée.")
          expect(page).to have_selector("h1", text: "Récupérer un url")
          expect(page).to have_xpath("//img[contains(@src, '#{good_image}')]")
          expect(page).to have_content(image_picture_url(Picture.last, :only_path => true, :key => Picture.last.access_key))
          expect(page).to have_link("Supprimer cette image", href: picture_path(Picture.last))
          expect { click_link("Supprimer cette image", href: picture_path(Picture.last)) }.to change(Picture, :count).by(-1)
        end
        
        let!(:picture) { Picture.last }
        
        describe "and visits pictures page" do
          before { visit pictures_path }
          it do
            should have_selector("h1", text: "Vos images")
            should have_xpath("//img[contains(@src, '#{good_image}')]")
          end
        end
        
        describe "and visitor tries to see the picture with correct access key" do
          before { visit image_picture_path(picture, :key => picture.access_key) }
          it { should have_no_content(error_access_refused) }
        end
        
        describe "and visitor tries to see the picture with incorrect access key" do
          before { visit image_picture_path(picture, :key => picture.access_key + "WRONG") }
          it { should have_content(error_access_refused) }
        end
      end
    end
  end
end
