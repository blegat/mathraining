require 'kramdown'
module MarkdownHelper

  def markdown_render(text)
    Kramdown::Document.new(text).to_html.html_safe
  end

end
