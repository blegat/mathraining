require 'spec_helper'

describe "theories/new" do
  before(:each) do
    assign(:theory, stub_model(Theory,
      :title => "MyString",
      :content => "MyText",
      :chapter_id => 1,
      :order => 1
    ).as_new_record)
  end

  it "renders new theory form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => theories_path, :method => "post" do
      assert_select "input#theory_title", :name => "theory[title]"
      assert_select "textarea#theory_content", :name => "theory[content]"
      assert_select "input#theory_chapter_id", :name => "theory[chapter_id]"
      assert_select "input#theory_order", :name => "theory[order]"
    end
  end
end
