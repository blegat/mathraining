require 'spec_helper'

describe "chapters/edit" do
  before(:each) do
    @chapter = assign(:chapter, stub_model(Chapter,
      :name => "MyString",
      :description => "MyText",
      :level => 1
    ))
  end

  it "renders the edit chapter form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => chapters_path(@chapter), :method => "post" do
      assert_select "input#chapter_name", :name => "chapter[name]"
      assert_select "textarea#chapter_description", :name => "chapter[description]"
      assert_select "input#chapter_level", :name => "chapter[level]"
    end
  end
end
