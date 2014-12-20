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
      flash.now[:danger] = object.errors.full_messages.to_sentence
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
    # Deal with '<' signs
    html_text = fix_irregular_html(html_text)
    tex_text = nokogiri_to_tex(Nokogiri::HTML(html_text).children[1])
    tex_text.gsub(/&lt;/, "<").
      gsub(/&gt;/, ">").
      gsub(/&amp;/, "&").
      gsub(/\$\$\s*\\begin{align\*}/,"\\begin{align*}").
      gsub(/\\end{align\*}\s*\$\$/,"\\end{align*}").
      gsub(/\$\$\s*\\begin{align}/,"\\begin{align}").
      gsub(/\\end{align}\s*\$\$/,"\\end{align}")
  end

  private

  # source: https://gist.github.com/rngtng/796571
  def fix_irregular_html(html)
    regexp = /<([^<>]*)(<|$)/
    #we need to do this multiple time as regex are overlapping
    while (fixed_html = html.gsub(regexp, "&lt;\\1\\2")) && fixed_html != html
      html = fixed_html
    end
    fixed_html
  end

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
        before = "\\begin{itemize}\n"
        after = "\\end{itemize}"
      when "ol"
        before = "\\begin{enumerate}\n"
        after = "\\end{enumerate}"
      when "li"
        before = "\\item "
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
  
  def options_for_select_with_style( container, selected=nil )
    container = container.to_a if Hash === container
    options_for_select = container.inject([]) do |options, element|
      text, value = option_text_and_value(element)
      selected_attribute = ' selected="selected"' if option_value_selected?(value, selected)
      style = " style=\"#{element[1]}\"" if element[1] && element[1]!=value
      options << %(<option value="#{html_escape(value.to_s)}"#{selected_attribute}#{style}>#{html_escape(text.to_s)}</option>)
    end
    options_for_select.join("\n")
  end
  
  def bbcode(m)
  (h m.gsub(/\\][ \r]*\n/,'\] ').gsub(/\$\$[ \r]*\n/,'$$ ')).gsub(/\n/, '<br>').gsub(/\[b\](.*?)\[\/b\]/mi, '<b>\1</b>').gsub(/\[u\](.*?)\[\/u\]/mi, '<u>\1</u>').gsub(/\[i\](.*?)\[\/i\]/mi, '<i>\1</i>').gsub(/\[url=(?:&quot;)?(.*?)(?:&quot;)?\](.*?)\[\/url\]/mi, '<a target=\'blank\' href=\'\1\'>\2</a>')
  end

end
