module ApplicationHelper
  # Returns the full title on a per-page basis.
  def full_title(page_title)
    base_title = "Mathraining"
    if page_title.empty?
      base_title
    else
      "#{page_title} | #{base_title}"
    end
  end

  # Flash all errors
  def flash_errors(object)
    unless object.errors.empty?
      flash.now[:danger] = object.errors.full_messages.to_sentence
    end
  end

  # Get all errors
  def get_errors(object)
    unless object.errors.empty?
      object.errors.full_messages.to_sentence
    end
  end

  private

  # To read bbcode on user side
  def bbcode(m)
    (h m.gsub(/\\\][ \r]*\n/,'\] ').
    gsub(/\$\$[ \r]*\n/,'$$ ')).
    gsub(/\[b\](.*?)\[\/b\]/mi, '<b>\1</b>').
    gsub(/\[u\](.*?)\[\/u\]/mi, '<u>\1</u>').
    gsub(/\[i\](.*?)\[\/i\]/mi, '<i>\1</i>').
    gsub(/\[url=(?:&quot;)?(.*?)(?:&quot;)?\](.*?)\[\/url\]/mi, '<a target=\'blank\' href=\'\1\'>\2</a>').
    gsub(/\[hide=(?:&quot;)?(.*?)(?:&quot;)?\][ \r\n]*(.*?)[ \r\n]*\[\/hide\]/mi, '[hide=\1]\2[/hide]').
    gsub(/\n/, '<br>').
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

  # To read code on admin side
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

  # Method to deal with clues
  def replace_indice(m)
    m2 = m.gsub(/<\/indice>[ \r]*<br\/>/, "</indice>")
    
    while m2.sub!(/<indice>(.*?)<\/indice>/mi) {"<div class='clue-bis'><div><a href='#' onclick='return Clue.toggle(0)' class='btn btn-default btn-grey'>Indice</a></div><div id='indice0' class='clue-hide'><div class='clue-content'>#{$1}</div></div></div>"}
    end
    
    return m2
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
  
  # Write 12 juin 2009
  def write_date_only_small(date_utc)
    date = date_utc.in_time_zone
    return "#{ date.day }/#{'0' if date.month < 10}#{ date.month }/#{date.year-2000}"
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
  
  # Tells if current user has enough points for problems
  def has_enough_points
    if !@signed_in
      return false
    elsif current_user.sk.admin?
      return true
    else
      return (current_user.sk.rating >= 200)
    end
  end
end
