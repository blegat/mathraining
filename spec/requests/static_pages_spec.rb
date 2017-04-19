# -*- coding: utf-8 -*-
require "spec_helper"

describe "Static pages" do

	subject { page }

	describe "Home page" do
		before { visit root_path }

		it { should have_selector("h1", text: "Actualités") }
	end

	describe "About page" do
		before { visit about_path }

		it { should have_selector("h1", text: "À propos") }
	end

	describe "Contact page" do
		before { visit contact_path }

		it { should have_selector("h1", text: "Contact") }
	end
end
