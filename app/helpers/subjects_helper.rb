module SubjectsHelper

  public

  def write_date_from_now(date, datenow)
    between_dates = (datenow.to_i - date.to_i)
    if between_dates >= 24*60*60
      return write_date(date)
    elsif between_dates >= 60*60
      minute = (between_dates/60).floor
      heure = (minute / 60).floor
      minute = minute - 60*heure
      return "il y a #{heure} heure#{'s' if heure > 1}, #{minute} minute#{'s' if minute > 1}"
    elsif between_dates >= 60
      minute = (between_dates/60).floor
      return "il y a #{minute} minute#{'s' if minute > 1}"
    else
      seconde = between_dates.floor
      return "il y a #{seconde} seconde#{'s' if seconde > 1}"
    end
  end

  def get_problem_category_name(section_name)
    section_name = section_name.downcase
    if section_name[0] == "a" or section_name[0] == "é" or section_name[0] == "i"
      return "Problèmes d'" + section_name
    else
      return "Problèmes de " + section_name
    end
  end>

  def get_category_name(subject)
    if !subject.category.nil?
      return subject.category.name
    elsif !subject.section.nil?
      if subject.chapter.nil?
        return subject.section.name
      else
        return subject.chapter.name
      end
    else
      return ""
    end
  end
end
