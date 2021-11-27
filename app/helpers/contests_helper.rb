module ContestsHelper

  public

  # Message du Forum à la publication d'un concours
  def get_new_contest_forum_message(contest)
    text = "Le [url=" + contest_path(contest) + "]Concours ##{contest.number}[/url], organisé par "
    nb = contest.organizers.count
    i = 0
    contest.organizers.order(:last_name, :first_name).each do |o|
      text = text + "[b]" + o.name + "[/b]"
      i = i+1
      if i == nb-1
        text = text + " et "
      elsif i < nb-1
        text = text + ", "
      end
    end
    text = text + ", vient d'être mis en ligne. Il comporte [b]" + contest.contestproblems.count.to_s + " problème#{'s' if contest.contestproblems.count > 1}[/b] et démarrera le [b]" + write_date_only(contest.contestproblems.order(:number).first.start_time) + "[/b]. "
    text = text + " En voici la description :\r\n\r\n" + contest.description + "\r\n\r\n"
    contest.contestproblems.order(:number).each do |p|
      text = text + "Le Problème #" + p.number.to_s + " sera ouvert aux solutions du " + write_date_with_link_forum(p.start_time, contest, p) + " au " + write_date_with_link_forum(p.end_time, contest, p) + ".\r\n"
    end
    
    text = text + "Ces dates sont normalement définitives. Si toutefois elles venaient à changer alors une annonce sera faite pour prévenir tout le monde.\r\n\r\n"
    text = text + "Pour chaque problème du concours, un message automatique sera publié sur ce forum un jour avant sa publication, au moment de sa publication, et après sa correction. Si vous désirez également recevoir un rappel par e-mail un jour avant la publication de chaque problème, vous pouvez cliquer sur 'Suivre ce concours' en haut à droite de [url=" + contest_path(contest) + "]cette page[/url].\r\n\r\n"
    if contest.medal?
      text = text + "Des médailles et mentions honorables seront attribuées à la fin de ce concours.\r\n\r\n"
    else
      text = text + "Il n'y aura pas de médailles et mentions honorables pour ce concours.\r\n\r\n"
    end
    text = text + "Ce sujet peut être utilisé pour échanger vos commentaires sur le concours, mais il vous est demandé de ne pas vous entraider ;-)\r\n\r\n"
    text = text + "Bonne chance à tous, et surtout bon amusement ! :-)"
    
    return text
  end
  
  # Message du Forum à la correction d'un problème
  def get_new_correction_forum_message(contest, contestproblem)
    text = "Le [url=" + contestproblem_path(contestproblem) + "]Problème ##{contestproblem.number}[/url] du [url=" + contest_path(contest) + "]Concours ##{contest.number}[/url] a été corrigé.\r\n\r\n"
    
    nb_sol = contestproblem.contestsolutions.where("score = 7 AND official = ?", false).count
    
    if nb_sol == 0
      text = text + "Malheureusement, [b]personne[/b] n'a obtenu la note maximale !"
    elsif nb_sol == 1
      text = text + "Seule [b]une seule[/b] personne a obtenu la note maximale : "
    else
      text = text + "Les [b]" + nb_sol.to_s + "[/b] personnes suivantes ont obtenu la note maximale : "
    end
    
    i = 0
    contestproblem.contestsolutions.where("score = 7 AND official = ?", false).order(:user_id).each do |s|
      text = text + s.user.name
      i = i+1
      if (i == nb_sol)
        text = text + "."
      elsif (i == nb_sol - 1)
        text = text + " et "
      else
        text = text + ", "
      end
    end
    
    text = text + "\r\n\r\n"
    if contest.contestproblems.where("status < 4").count > 0
      text = text + "Le nouveau classement général suite à cette correction peut être consulté à [url=" + contest_path(contest, :tab => 1) + "]cet endroit[/url]."    
    else
      text = text + "Il s'agissait du dernier problème. Le classement final peut être consulté à [url=" + contest_path(contest, :tab => 1) + "]cet endroit[/url], et quelques statistiques se trouvent [url=" + contest_path(contest, :tab => 2) + "]ici[/url]."    
    end
    
    return text
  end
  
  # Message du Forum un jour avant la publication d'un ou plusieurs problèmes
  def get_problems_in_one_day_forum_message(contest, contestproblems)
    if contestproblems.size == 1
      plural = false
      text = "Le Problème ##{contestproblems[0].number}"
    else
      plural = true
      text = "Les Problèmes"
      i = 0
      contestproblems.each do |cp|
        if (i == contestproblems.size-1)
          text = text + " et"
        elsif (i > 0)
          text = text + ","
        end
        text = text + " ##{cp.number}"
        i = i+1
      end
    end
    text = text + " du [url=" + Rails.application.routes.url_helpers.contest_path(contest) + "]Concours ##{contest.number}[/url] #{plural ? "seront" : "sera"} publié#{plural ? "s" : ""} dans un jour, c'est-à-dire le " + write_date_with_link_forum(contestproblems[0].start_time, contest, contestproblems[0]) + " (heure belge)."
    
    return text
  end
  
  # Message du Forum au moment de la publication d'un ou plusieurs problèmes
  def get_problems_now_forum_message(contest, contestproblems)
    if contestproblems.size == 1
      plural = false
      text = "Le [url=" + Rails.application.routes.url_helpers.contestproblem_path(contestproblems[0]) + "]Problème ##{contestproblems[0].number}[/url]"
    else
      plural = true
      text = "Les Problèmes"
      i = 0
      contestproblems.each do |cp|
        if (i == contestproblems.size-1)
          text = text + " et"
        elsif (i > 0)
          text = text + ","
        end
        text = text + " [url=" + Rails.application.routes.url_helpers.contestproblem_path(cp) + "]##{cp.number}[/url]"
        i = i+1
      end
    end
    text = text + " du [url=" + Rails.application.routes.url_helpers.contest_path(contest) + "]Concours ##{contest.number}[/url] #{plural ? "sont" : "est"} maintenant accessible#{plural ? "s" : ""}, et les solutions sont acceptées jusqu'au " + write_date_with_link_forum(contestproblems[0].end_time, contest, contestproblems[0]) + " (heure belge)."
    
    return text
  end
end
