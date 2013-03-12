require 'spec_helper'

describe "theories/edit" do
  before(:each) do
    @theory = assign(:theory, stub_model(Theory,
      :title => "MyString",
      :content => "MyText",
      :chapter_id => 1,
      :order => 1
    ))
  end

  it "renders the edit theory form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => theories_path(@theory), :method => "post" do
      assert_select "input#theory_title", :name => "theory[title]"
      assert_select "textarea#theory_content", :name => "theory[content]"
      assert_select "input#theory_chapter_id", :name => "theory[chapter_id]"
      assert_select "input#theory_order", :name => "theory[order]"
    end
  end
end
