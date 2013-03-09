require 'spec_helper'

describe "chapters/new" do
  before(:each) do
    assign(:chapter, stub_model(Chapter,
      :name => "MyString",
      :description => "MyText",
      :level => 1
    ).as_new_record)
  end

  it "renders new chapter form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => chapters_path, :method => "post" do
      assert_select "input#chapter_name", :name => "chapter[name]"
      assert_select "textarea#chapter_description", :name => "chapter[description]"
      assert_select "input#chapter_level", :name => "chapter[level]"
    end
  end
end
