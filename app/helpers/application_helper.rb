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

  # Pour mettre des espaces dans un select (sur le forum)
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

  # Pour les messages avec bbcode
  def bbcode(m)
    (h m.gsub(/\\\][ \r]*\n/,'\] ').
    gsub(/\$\$[ \r]*\n/,'$$ ')).
    gsub(/\[hide=(?:&quot;)?(.*?)(?:&quot;)?\][ \r\n]*(.*?)[ \r\n]*\[\/hide\]/mi, '[hide=\1]\2[/hide]').
    gsub(/\n/, '<br>').
    gsub(/\[b\](.*?)\[\/b\]/mi, '<b>\1</b>').
    gsub(/\[u\](.*?)\[\/u\]/mi, '<u>\1</u>').
    gsub(/\[i\](.*?)\[\/i\]/mi, '<i>\1</i>').
    gsub(/\[url=(?:&quot;)?(.*?)(?:&quot;)?\](.*?)\[\/url\]/mi, '<a target=\'blank\' href=\'\1\'>\2</a>').
    gsub(/\:\-\)/, image_tag("Smiley1.gif", alt: ":-)")).
    gsub(/\:\-\(/, image_tag("Smiley2.gif", alt: ":-(")).
    gsub(/\:\-[D]/, image_tag("Smiley3.gif", alt: ":-D")).
    gsub(/\:\-[O]/, image_tag("Smiley4.gif", alt: ":-O")).
    gsub(/\:\-[P]/, image_tag("Smiley5.gif", alt: ":-P")).
    gsub(/\:&#39;\(/, image_tag("Smiley6.gif", alt: ":'(")).
    gsub(/\;\-\)/, image_tag("Smiley7.gif", alt: ";-)")).
    gsub(/\:\-\|/, image_tag("Smiley8.gif", alt: ":-|"))
    .gsub(/[3]\:\[/, image_tag("Smiley9.gif", alt: "3:["))
  end

  # Pour les trucs coté admins
  def htmlise(m)
    m2 = m.gsub(/<hr>[ \r]*\n/,'<hr>').
    gsub(/\\\][ \r]*\n/,'\] ').
    gsub(/\$\$[ \r]*\n/,'$$ ').
    gsub(/<\/h2>[ \r]*\n/,'</h2>').
    gsub(/<\/h3>[ \r]*\n/,'</h3>').
    gsub(/<\/h4>[ \r]*\n/,'</h4>').
    gsub(/<\/ol>[ \r]*\n/, '</ol>').
    gsub(/\n[ \r]*<\/ol>/, '</ol>').
    gsub(/<\/ul>[ \r]*\n/, '</ul>').
    gsub(/\n[ \r]*<\/ul>/, '</ul>').
    gsub(/\n[ \r]*<li>/, '<li>').
    gsub(/<evidence>[ \r]*\n/, '<evidence>').
    gsub(/<\/evidence>[ \r]*\n/, '</evidence>').
    gsub(/<evidence>/, '<div class="evidence">').
    gsub(/<\/evidence>/, '</div>').
    gsub(/<\/result>[ \r]*\n/, '</result>').
    gsub(/<\/proof>[ \r]*\n/, '</proof>').
    gsub(/<\/remark>[ \r]*\n/, '</remark>').
    gsub(/<statement>[ \r]*\n/, '<statement>')
    
    while m2.sub!(/<result>(.*?)<statement>(.*?)<\/result>/mi) {"<div class='result-title'>#{$1}</div><div class='result-content'>#{$2}</div>"}
    end
    
    while m2.sub!(/<proof>(.*?)<statement>(.*?)<\/proof>/mi) {"<div class='proof-title'>#{$1}</div><div class='proof-content'>#{$2}</div>"}
    end
    
    while m2.sub!(/<remark>(.*?)<statement>(.*?)<\/remark>/mi) {"<div class='remark-title'>#{$1}</div><div class='remark-content'>#{$2}</div>"}
    end
    
    return m2.gsub(/\n/, '<br/>')
  end
  
  def replace_indice(m)
    m2 = m.gsub(/<\/indice>[ \r]*<br\/>/, "</indice>")
    
    while m2.sub!(/<indice>(.*?)<\/indice>/mi) {"<div class='clue-bis'><div><a href='#' onclick='return Clue.toggle(0)' class='btn btn-default btn-grey'>Indice</a></div><div id='indice0' class='clue-hide'><div class='clue-content'>#{$1}</div></div></div>"}
    end
    
    return m2
  end
  
  def write_date(date)
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    return "#{ date.day } #{ mois[date.month-1]} #{date.year} à #{date.hour}h#{"0" if date.min < 10}#{date.min}"
  end
  
  def write_date_only(date)
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    return "#{ date.day } #{ mois[date.month-1]} #{date.year}"
  end
  
  def write_date_with_day(date)
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    jour = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
    return "#{ jour[date.wday] } #{ date.day } #{ mois[date.month-1]} #{date.year} à #{date.hour}h#{"0" if date.min < 10}#{date.min}"
  end
  
  def write_date_only_with_day(date)
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    jour = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
    return "#{ jour[date.wday] } #{ date.day } #{ mois[date.month-1]} #{date.year}"
  end
  
  def write_date_with_link(date, contest, contestproblem)
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    jour = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
    return link_to "#{ jour[date.wday] } #{ date.day } #{ mois[date.month-1]} #{date.year} à #{date.hour}h#{"0" if date.min < 10}#{date.min}", "https://www.timeanddate.com/worldclock/fixedtime.html?msg=Mathraining+-+Concours+%23#{contest.number}+-+Probl%C3%A8me+%23#{contestproblem.number}&iso=#{date.year}#{'0' if date.month < 10}#{date.month}#{'0' if date.day < 10}#{date.day}T#{'0' if date.hour < 10}#{date.hour}#{'0' if date.min < 10}#{date.min}&p1=48", :target => "blank_"
  end
  
  def write_date_with_link_forum(date, contest, contestproblem)
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    jour = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
    return "[url=https://www.timeanddate.com/worldclock/fixedtime.html?msg=Mathraining+-+Concours+%23#{contest.number}+-+Probl%C3%A8me+%23#{contestproblem.number}&iso=#{date.year}#{'0' if date.month < 10}#{date.month}#{'0' if date.day < 10}#{date.day}T#{'0' if date.hour < 10}#{date.hour}#{'0' if date.min < 10}#{date.min}&p1=48]#{ jour[date.wday] } #{ date.day } #{ mois[date.month-1]} #{date.year} à #{date.hour}h#{"0" if date.min < 10}#{date.min}[/url]"
  end
  
  def pluriel(level)
    newlevel = ""
    (0..level.size-1).each do |i|
      if level[i] == ' '
        newlevel += 's'
      end
      newlevel += level[i]
    end
    newlevel += 's'
    return newlevel
  end
end
