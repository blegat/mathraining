require 'kramdown'
require 'redcarpet'
module MarkdownHelper

  def kramdown_render(text)
    Kramdown::Document.new(text).to_html.html_safe
  end

  def kramdown_to_latex(text)
    Kramdown::Document.new(text).to_latex
  end

  def redcarpet_render(text)
    rndr = Redcarpet::Render::HTML.new(no_links: true,
                                       hard_wrap: true)
    markdown = Redcarpet::Markdown.new(rndr,
                                       autolink: true,
                                       no_intra_emphasis: true,
                                       fenced_code_blocks: true,
                                       space_after_headers: true)
    markdown.render(text).html_safe
  end

  def markdown_render(text)
    #redcarpet_render(text)
    kramdown_render(text)
  end

  def markdown_to_latex(text)
    kramdown_to_latex(text)
  end

end
