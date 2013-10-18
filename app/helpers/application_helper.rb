require 'nokogiri'

module ApplicationHelper
  # Returns the full title on a per-page basis.
  def full_title(page_title)
    base_title = "Mathraining"
    if page_title.empty?
      base_title
    else
      "#{base_title} | #{page_title}"
    end
  end

  def flash_errors(object)
    unless object.errors.empty?
      flash.now[:error] = object.errors.full_messages.to_sentence
    end
  end
  def get_errors(object)
    unless object.errors.empty?
      object.errors.full_messages.to_sentence
    end
  end
  def troncate(str, len)
    if str.length <= len
      return str
    else
      # FIXME avoid cutting en math expr
      # "Posons $x = 1$" -> "Posons $x..." should be avoided
      return "#{str.to(len-1)}..."
    end
  end

  def html_to_tex(html_text)
    nokogiri_to_tex(Nokogiri::HTML(html_text).children[1])
  end

  private

  def nokogiri_to_tex(node)
    if node.class == Nokogiri::XML::Element
      before = ""
      after = ""
      case node.name
      when "h4" then
        before = "\\subsubsection{"
        after = "}"
      when "h5" then
        before = "\\paragraph{"
        after = "}"
      when "p" then
        before = "\n"
        after = "\n"
      when "i" then
        before = "\\textit{"
        after = "}"
      when "b" then
        before = "\\textbf{"
        after = "}"
      when "ul"
        before = "\\begin{itemize}"
        after = "\\end{itemize}"
      when "ol"
        before = "\\begin{enumerate}"
        after = "\\end{enumerate}"
      when "li"
        before = "\\item"
      end
      content = node.children.inject("") do |sum, child|
        "#{sum}#{nokogiri_to_tex(child)}"
      end
      "#{before}#{content}#{after}"
    elsif node.class == Nokogiri::XML::Text
      node
    else
      raise node.class.to_s
      ""
    end
  end

end
