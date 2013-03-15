module MarkdownHelper

  def markdown_render(text)
    rndr = Redcarpet::Render::HTML.new(:no_links => true,
                                       :hard_wrap => true)
    markdown = Redcarpet::Markdown.new(rndr,
                                       :autolink => true,
                                       :space_after_headers => true)
    markdown.render(text).html_safe
  end

end
