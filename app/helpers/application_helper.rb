module ApplicationHelper
  # Returns the full title on a per-page basis.
  def full_title(page_title)
    base_title = "Mathraining"
    if page_title.empty?
      return base_title
    else
      return page_title + " | " + base_title
    end
  end
  
  # Transform list of errors in readable html list
  def errors_to_list(errors)
    if errors.count <= 1
      s = "Une erreur est survenue."
    else
      s = "Plusieurs erreurs sont survenues."
    end
    
    if errors.count > 0
      s += "\n<ul>\n"
      errors.each do |msg|
        s += "<li>#{ msg }</li>\n"
      end
      s += "</ul>"
    end
    
    return s.html_safe
  end
  
  # Get html list of errors for an invalid object
  def error_list_for(object)
    return errors_to_list(object.errors.full_messages)
  end

  private

  # To read bbcode on user side (should be similar to preview.js)
  def bbcode(m)
    return (h m).
    gsub(/\\\][ \r]*\n/,'\] ').
    gsub(/\$\$[ \r]*\n/,'$$ ').
    gsub(/\[b\](.*?)\[\/b\]/mi, '<b>\1</b>').
    gsub(/\[u\](.*?)\[\/u\]/mi, '<u>\1</u>').
    gsub(/\[i\](.*?)\[\/i\]/mi, '<i>\1</i>').
    gsub(/\[url=(.*?)\](.*?)\[\/url\]/mi, '<a target=\'blank\' href=\'\1\'>\2</a>').
    gsub(/\[hide=(.*?)\][ \r\n]*/mi, '[hide=\1]').
    gsub(/[ \r\n]*\[\/hide\]/mi, '[/hide]').
    gsub(/\:\-\)/,    image_tag("Smiley1.png", alt: ":-)", width: "20px")).
    gsub(/\:\-\(/,    image_tag("Smiley2.png", alt: ":-(", width: "20px")).
    gsub(/\:\-[D]/,   image_tag("Smiley3.png", alt: ":-D", width: "20px")).
    gsub(/\:\-[O]/,   image_tag("Smiley4.png", alt: ":-O", width: "20px")).
    gsub(/\:\-[P]/,   image_tag("Smiley5.png", alt: ":-P", width: "20px")).
    gsub(/\:&#39;\(/, image_tag("Smiley6.png", alt: ":'(", width: "20px")).
    gsub(/\;\-\)/,    image_tag("Smiley7.png", alt: ";-)", width: "20px")).
    gsub(/\:\-\|/,    image_tag("Smiley8.png", alt: ":-|", width: "20px")).
    gsub(/[3]\:\[/,   image_tag("Smiley9.png", alt: "3:[", width: "20px")).
    gsub(/\n/, '<br/>').
    html_safe
  end

  # To read code on admin side (should be similar to preview.js)
  def htmlise(m, replace_indice = false)
    m2 = (h m).
    gsub(/&quot;/, '"').
    gsub(/&#34;/, '"').
    gsub(/&apos;/, '\'').
    gsub(/&#39;/, '\'').
    gsub(/\\\][ \r]*\n/,'\] ').
    gsub(/\$\$[ \r]*\n/,'$$ ').
    gsub(/&lt;b&gt;(.*?)&lt;\/b&gt;/mi, '<b>\1</b>').
    gsub(/&lt;u&gt;(.*?)&lt;\/u&gt;/mi, '<u>\1</u>').
    gsub(/&lt;i&gt;(.*?)&lt;\/i&gt;/mi, '<i>\1</i>').
    gsub(/&lt;hr&gt;/, '<hr>').
    gsub(/<hr>[ \r]*\n/,'<hr>').
    gsub(/&lt;h2&gt;(.*?)&lt;\/h2&gt;/mi, '<h2>\1</h2>').
    gsub(/&lt;h3&gt;(.*?)&lt;\/h3&gt;/mi, '<h3>\1</h3>').
    gsub(/&lt;h4&gt;(.*?)&lt;\/h4&gt;/mi, '<h4>\1</h4>').
    gsub(/&lt;h5&gt;(.*?)&lt;\/h5&gt;/mi, '<h5>\1</h5>').
    gsub(/\n[ \r]*<h2>/,'<h2 class="mt-3">').
    gsub(/\n[ \r]*<h3>/,'<h3 class="mt-3">').
    gsub(/\n[ \r]*<h4>/,'<h4 class="mt-3">').
    gsub(/\n[ \r]*<h5>/,'<h5 class="mt-3">').
    gsub(/<\/h2>[ \r]*\n/,'</h2>').
    gsub(/<\/h3>[ \r]*\n/,'</h3>').
    gsub(/<\/h4>[ \r]*\n/,'</h4>').
    gsub(/<\/h5>[ \r]*\n/,'</h5>').
    gsub(/&lt;ol&gt;/mi, '<ol>').
    gsub(/&lt;ol (.*?)&gt;/mi, '<ol \1>').
    gsub(/&lt;ul&gt;/mi, '<ul>').
    gsub(/&lt;ul (.*?)&gt;/mi, '<ul \1>').
    gsub(/&lt;li&gt;/mi, '<li>').
    gsub(/&lt;li (.*?)&gt;/mi, '<li \1>').
    gsub(/&lt;\/ol&gt;/mi, '</ol>').
    gsub(/&lt;\/ul&gt;/mi, '</ul>').
    gsub(/&lt;\/li&gt;/mi, '</li>').
    gsub(/<ol/, '<ol class="my-1"').
    gsub(/<ul/, '<ul class="my-1"').
    gsub(/<\/ol>[ \r]*\n/, '</ol>').
    gsub(/\n[ \r]*<\/ol>/, '</ol>').
    gsub(/<\/ul>[ \r]*\n/, '</ul>').
    gsub(/\n[ \r]*<\/ul>/, '</ul>').
    gsub(/\n[ \r]*<li/, '<li').
    gsub(/&lt;result&gt;(.*?)&lt;statement&gt;(.*?)&lt;\/result&gt;/mi, '<result>\1<statement>\2</result>').
    gsub(/&lt;proof&gt;(.*?)&lt;statement&gt;(.*?)&lt;\/proof&gt;/mi, '<proof>\1<statement>\2</proof>').
    gsub(/&lt;remark&gt;(.*?)&lt;statement&gt;(.*?)&lt;\/remark&gt;/mi, '<remark>\1<statement>\2</remark>').
    gsub(/<result>[ \r]*\n/, '<result>').
    gsub(/<\/result>[ \r]*\n/, '</result>').
    gsub(/<proof>[ \r]*\n/, '<proof>').
    gsub(/<\/proof>[ \r]*\n/, '</proof>').
    gsub(/<remark>[ \r]*\n/, '<remark>').
    gsub(/<\/remark>[ \r]*\n/, '</remark>').
    gsub(/<statement>[ \r]*\n/, '<statement>').
    gsub(/<result>(.*?)<statement>(.*?)<\/result>/mi, '<div class=\'result-title\'>\1</div><div class=\'result-content\'>\2</div>').
    gsub(/<proof>(.*?)<statement>(.*?)<\/proof>/mi, '<div class=\'proof-title\'>\1</div><div class=\'proof-content\'>\2</div>').
    gsub(/<remark>(.*?)<statement>(.*?)<\/remark>/mi, '<div class=\'remark-title\'>\1</div><div class=\'remark-content\'>\2</div>').
    gsub(/&lt;center&gt;(.*?)&lt;\/center&gt;/mi, '<center>\1</center>').
    gsub(/&lt;img (.*?)\/&gt;/mi, '<img \1/>').
    gsub(/&lt;a (.*?)&gt;(.*?)&lt;\/a&gt;/mi, '<a \1>\2</a>').
    gsub(/&lt;div (.*?)&gt;(.*?)&lt;\/div&gt;/mi, '<div \1>\2</div>').
    gsub(/&lt;span (.*?)&gt;(.*?)&lt;\/span&gt;/mi, '<span \1>\2</span>').
    gsub(/\n/, '<br/>')
    
    if replace_indice
      m2 = m2.
      gsub(/&lt;indice&gt;(.*?)&lt;\/indice&gt;/mi, '<indice>\1</indice>').
      gsub(/<\/indice>[ \r]*<br\/>/, '</indice>').
      gsub(/<indice>(.*?)<\/indice>/mi, '<div class=\'clue-bis\'><div><button onclick=\'return Clue.toggle(0);\' class=\'btn btn-ld-light-dark\'>Indice</button></div><div id=\'indice0\' class=\'clue-hide\'><div class=\'clue-content\'>\1</div></div></div>')
    end
    
    return m2.html_safe
  end
  
  # Replace hidden text in m, where "[hide=" is in position a, "]" in position b, and "[/hide]" in position c
  def replace_hidden_text_impl(m, a, b, c, i)
    return (a > 0 ? m[0..(a-1)] : "") \
            + (Rails.env.test? ? "(X#{i})" : "<div class='clue'><div><button onclick='return Clue.toggle(#{i})' class='btn btn-ld-light-dark'>".html_safe) \
            + m[(a+6)..(b-1)] \
            + (Rails.env.test? ? "(Y#{i})" : "</button></div><div id='indice#{i}' class='clue-hide'><div class='clue-content'>".html_safe) \
            + m[(b+1)..(c-1)] \
            + (Rails.env.test? ? "(Z#{i})" :  "</div></div></div>".html_safe) \
            + m[(c+7)..]
  end
  
  # Return [new_m, c, new_i] if [/hide] was found in position c (with c = nil if no [/hide] found)
  def process_hidden_text_rec(m, cur, i)
    a = m.index("[hide=", cur)
    c = m.index("[/hide]", cur)
    if (!a.nil? && (c.nil? || a < c)) # Next is [hide=...
      b = m.index("]", a+6)
      return [m, nil, i] if b.nil? # The ] was not found
      res = process_hidden_text_rec(m, b+1, i+1)
      if !res[1].nil? # Found matching [/hide] in position res[1]
        new_m = replace_hidden_text_impl(res[0], a, b, res[1], i)
        return process_hidden_text_rec(new_m, (new_m.size-res[0].size) + res[1]+7, res[2])
      else
        return res
      end
    end
    return [m, c, i] # With c possibly nil
  end
  
  # Process the [hide=Texte caché]Indice[/hide], and return [new_m, new_i]
  def process_hidden_text(m, i)
    res = [m, -1, i]
    loop do
      res = process_hidden_text_rec(res[0], res[1]+1, res[2])
      break if res[1].nil?
    end
    return [res[0], res[2]]
  end
  
  # Process the /latextest/ in LaTeX theory (to test LaTeX)
  def process_latex_test(m, id)
    return m.gsub(/\/latextest\//, "<div class=\"mb-2\"><div class=\"card text-bg-ld-light-dark mb-2\"><div class=\"card-body\" id=\"MathPreview#{ id }\"></div><div class=\"card-body hidden-latex\" id=\"MathBuffer#{ id }\"></div></div><textarea id=\"MathInput#{ id }\" class=\"form-control\" style=\"height:120px;\" placeholder=\"Rentrez ici le code $\LaTeX$ que vous souhaitez tester.\"></textarea></div><script>initAndUpdatePreviewSafeWhenPossible(\"#{ id }\", false)</script>").html_safe
  end

  # Write 21h50
  def write_hour(date_utc)
    date = date_utc.in_time_zone
    return "#{date.hour}h#{"0" if date.min < 10}#{date.min}"
  end

  # Write 21h
  def write_hour_only(date_utc)
    date = date_utc.in_time_zone
    return "#{date.hour}h"
  end
  
  # Write 12 juin 2009 à 21h50
  def write_date(date_utc)
    date = date_utc.in_time_zone
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    return "#{ date.day } #{ mois[date.month-1]} #{date.year} à #{date.hour}h#{"0" if date.min < 10}#{date.min}"
  end
  
  # Write 12 juin 2009
  def write_date_only(date_utc)
    date = date_utc.in_time_zone
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    return "#{ date.day } #{ mois[date.month-1]} #{date.year}"
  end
  
  # Write 12/06/09
  def write_date_only_small(date_utc)
    date = date_utc.in_time_zone
    return "#{ date.day }/#{'0' if date.month < 10}#{ date.month }/#{'0' if date.year-2000 < 10}#{date.year-2000}"
  end
  
  # Write vendredi 12 juin 2009 à 21h50
  def write_date_with_day(date_utc)
    date = date_utc.in_time_zone
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    jour = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
    return "#{ jour[date.wday] } #{ date.day } #{ mois[date.month-1]} #{date.year} à #{date.hour}h#{"0" if date.min < 10}#{date.min}"
  end
  
  # Write vendredi 12 juin 2009
  def write_date_only_with_day(date_utc)
    date = date_utc.in_time_zone
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    jour = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
    return "#{ jour[date.wday] } #{ date.day } #{ mois[date.month-1]} #{date.year}"
  end
  
  # Write vendredi 12 juin 2009 with HTML link to timeanddate.com
  def write_date_with_link(date_utc, contest, contestproblem)
    date = date_utc.in_time_zone
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    jour = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
    return link_to "#{ jour[date.wday] } #{ date.day } #{ mois[date.month-1]} #{date.year} à #{date.hour}h#{"0" if date.min < 10}#{date.min}", "https://www.timeanddate.com/worldclock/fixedtime.html?msg=Mathraining+-+Concours+%23#{contest.number}+-+Probl%C3%A8me+%23#{contestproblem.number}&iso=#{date.year}#{'0' if date.month < 10}#{date.month}#{'0' if date.day < 10}#{date.day}T#{'0' if date.hour < 10}#{date.hour}#{'0' if date.min < 10}#{date.min}&p1=48", :target => "blank_"
  end
  
  # Write vendredi 12 juin 2009 with bbcode link to timeanddate.com
  def write_date_with_link_forum(date_utc, contest, contestproblem)
    date = date_utc.in_time_zone
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    jour = ["dimanche", "lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi"]
    return "[url=https://www.timeanddate.com/worldclock/fixedtime.html?msg=Mathraining+-+Concours+%23#{contest.number}+-+Probl%C3%A8me+%23#{contestproblem.number}&iso=#{date.year}#{'0' if date.month < 10}#{date.month}#{'0' if date.day < 10}#{date.day}T#{'0' if date.hour < 10}#{date.hour}#{'0' if date.min < 10}#{date.min}&p1=48]#{ jour[date.wday] } #{ date.day } #{ mois[date.month-1]} #{date.year} à #{date.hour}h#{"0" if date.min < 10}#{date.min}[/url]"
  end
  
  # Get plural of 'Grand maître', 'Expert', ...
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
  
  # Tells if user has enough points for problems
  def has_enough_points(user) # user = nil for a non-signed-in user
    if user.nil?
      return false
    elsif user.admin?
      return true
    else
      return (user.rating >= 200)
    end
  end
  
  # Write 1234567 as 1 234 567 (with thin spaces)
  def write_readable_big_number(n)
    return "0" if n == 0
    m = n
    num_digits = 0
    n_string = ""
    while (m > 0)
      if num_digits % 3 == 0 && num_digits > 0
        n_string = "&thinsp;" + n_string
      end
      d = m % 10
      n_string = d.to_s + n_string
      m = m/10
      num_digits += 1
    end
    return n_string.html_safe
  end
  
  # Methods to write titles
  def title_1(x)
    return "<span class='h1'>".html_safe + x + "</span>".html_safe
  end
  
  def title_2(x, y)
    return "<span class='h3'>".html_safe + x + " ></span> <span class='h1'>".html_safe + y + "</span>".html_safe
  end
  
  def title_3(x, y, z)
    return "<span class='h4'>".html_safe + x + " ></span> <span class='h3'>".html_safe + y + " ></span> <span class='h1'>".html_safe + z + "</span>".html_safe
  end
  
  def title_4(x, y, z, t)
    return "<span class='h5'>".html_safe + x + " ></span> <span class='h4'>".html_safe + y +  " ></span> <span class='h3'>".html_safe + z + " ></span> <span class='h1'>".html_safe + t + "</span>".html_safe
  end
  
  # Titles concerning actualities
  def title_actualities(title)
    return title_2((link_to "Actualités", root_path), title)
  end
  
  # Titles concerning FAQ
  def title_faqs(title)
    return title_2((link_to "Questions fréquemment posées", faqs_path), title)
  end
  
  # Titles concerning pictures
  def title_pictures(title)
    return title_2((link_to "Vos images", pictures_path), title)
  end
  
  # Titles concerning privacypolicies
  def title_privacypolicies(title)
    return title_2((link_to "Politiques de confidentialité", privacypolicies_path), title)
  end
  
  # Titles concerning puzzles
  def title_puzzles(title)
    return title_2((link_to "Énigmes", puzzles_path), title)
  end
  
  # Titles concerning subjects
  def title_subjects(title)
    return title_2((link_to "Forum", subjects_path(:q => @q)), title)
  end
  
  # Titles concerning virtualtests
  def title_virtualtests(title)
    return title_2((link_to "Tests virtuels", virtualtests_path), title)
  end
  
  # Titles concerning sections / chapters / questions / theories
  def title_section(section, title)
    return title_3("Théorie", (link_to section.name, section), title)
  end
  
  def title_chapter(chapter, title)
    return title_4("Théorie", (link_to chapter.section.name, chapter.section), (link_to chapter.name, chapter), title)
  end
  
  def title_question(question, title)
    return title_4("Théorie", (link_to question.chapter.section.name, question.chapter.section), (link_to question.chapter.name, chapter_question_path(question.chapter, question)), title)
  end
  
  def title_theory(theory, title)
    return title_4("Théorie", (link_to theory.chapter.section.name, theory.chapter.section), (link_to theory.chapter.name, chapter_theory_path(theory.chapter, theory)), title)
  end
  
  # Titles concerning problems
  def title_problems(section, title)
    return title_3("Problèmes", (link_to section.name, section_problems_path(section)), title)
  end
  
  def title_problem(problem, title)
    return title_4("Problèmes", (link_to problem.section.name, section_problems_path(problem.section)), (link_to "Problème ##{ problem.number }", problem), title)
  end
  
  def title_submission(submission, title)
    return title_4("Problèmes", (link_to submission.problem.section.name, section_problems_path(submission.problem.section)), (link_to "Problème ##{ submission.problem.number }", problem_submission_path(submission.problem, submission)), title)
  end
  
  # Titles concerning contests / contestproblems
  def title_contests(title)
    return title_2((link_to "Concours", contests_path), title)
  end  
  
  def title_contest(contest, title)
    return title_3((link_to "Concours", contests_path), (link_to "Concours ##{@contest.number}", @contest), title)
  end
  
  def title_contestproblem(contestproblem, title)
    return title_4((link_to "Concours", contests_path), (link_to "Concours ##{contestproblem.contest.number}", contestproblem.contest), (link_to "Problème ##{contestproblem.number}", contestproblem), title)
  end
  
  # Titles concerning users
  def title_user(user, title)
    return title_2(user.linked_name, title)
  end
  
  def title_sanction(user, title)
    return title_3(user.linked_name, (link_to "Sanctionner", user_sanctions_path(user)), title)
  end
  
  def x_icon
    return 'x-mid.svg'
  end
  
  def v_icon
    return 'check-lg.svg'
  end
  
  def dash_icon
    return 'dash-mid.svg'
  end
  
  def star_icon
    return 'star-fill-small.svg'
  end
  
  def warning_icon
    return 'exclamation-triangle.svg'
  end
  
  def blocked_icon
    return 'x-circle.svg'
  end
  
  def ruby_to_javascript(arr)
    t = "["
    prems = true
    arr.each do |a|
      t << "," if !prems
      prems = false
      t << a.to_s
    end
    t << "]"
    return t.html_safe
  end

  def ruby_to_javascript_string(arr)
    t = "["
    prems = true
    arr.each do |a|
      t << "," if !prems
      prems = false
      t << "'" << a << "'"
    end
    t << "]"
    return t.html_safe
  end
end
