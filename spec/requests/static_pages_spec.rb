# -*- coding: utf-8 -*-
require 'spec_helper'

describe "Static pages" do

	subject { page }

	shared_examples_for "all static pages" do
		it { should have_selector('h1',    text: heading) }
		it { should have_selector('title', text: full_title(page_title)) }
	end

    describe "Home page" do
      before { visit root_path }
      let(:heading)    { 'OMB training' }
      let(:page_title) { '' }

      it_should_behave_like "all static pages"
      it { should_not have_selector 'title', text: '| Home' }

    end

	describe "Help page" do
		before { visit help_path }
		let(:heading) { 'Aide' }
		let(:page_title) { 'Aide' }

		it_should_behave_like "all static pages"
	end

	describe "About page" do
		before { visit about_path }
		let(:heading) { 'A propos' }
		let(:page_title) { 'A propos' }

		it_should_behave_like "all static pages"
	end

	describe "Contact page" do
		before { visit contact_path }
		let(:heading) { 'Contact' }
		let(:page_title) { 'Contact' }

		it_should_behave_like "all static pages"
	end

	it "should have the right links on the layout" do
		visit root_path
		click_link "A propos"
		page.should have_selector 'title', text: full_title('A propos')
		click_link "Contact"
		page.should have_selector 'title', text: full_title('Contact')
		click_link "Accueil"
		click_link "Inscrivez-vous maintenant!"
		page.should have_selector 'title', text: full_title('Inscription')
		click_link "OMB training"
		page.should have_selector 'title', text: full_title('')
	end
end
