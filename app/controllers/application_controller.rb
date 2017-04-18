#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include ApplicationHelper

  before_action :active_user
  before_action :check_up
  before_action :warning

  ########## PARTIE PRIVEE ##########
  private
  
  def warning
  	#flash[:info] = "Attention! Ce <b>vendredi 14 avril 2017</b>, une mise à jour du site aura lieu et celui-ci sera inaccessible pendant une bonne partie de la journée. Merci pour votre compréhension.".html_safe
  end

  # Vérifie que l'utilisateur n'a pas eu son compte désactivé.
  def active_user
  	$allcolors = Color.order(:pt).to_a
  	@ss = signed_in?
    if @ss && !current_user.active
      flash[:danger] = "Ce compte a été désactivé et n'est plus accessible."
      sign_out
      redirect_to root_path
    end
  end

  # Regarde s'il y a un test virtuel qui vient de se terminer
  def check_up
    maintenant = DateTime.now.to_i
    Takentest.where(status: 0).each do |t|
      debut = t.takentime.to_i
      if debut + t.virtualtest.duration*60 < maintenant
        t.status = 1
        t.save
        u = t.user
        v = t.virtualtest
        v.problems.each do |p|
          p.submissions.where(user_id: u.id, intest: true).each do |s|
            s.visible = true
            s.save
          end
        end
      end
    end
  end

  # Vérifie qu'il ne s'agit pas d'un administrateur dans la peau de quelqu'un
  def notskin_user
    if current_user.other
      flash[:danger] = "Vous ne pouvez pas effectuer cette action dans la peau de quelqu'un."
      redirect_to(:back)
    end
  end

  # Vérifie qu'on est administrateur
  def admin_user
    redirect_to root_path unless current_user.sk.admin?
  end

  # Vérifie que l'on est root
  def root_user
    redirect_to root_path unless current_user.sk.root
  end
  
  # Recalcule les scores de tout le monde
  def point_attribution_all
  	newrating = Array.new
  	newpartial = Array.new
  	existpartial = Array.new
  	exercise_value = Array.new
  	exercise_section = Array.new
  	qcm_value = Array.new
  	qcm_section = Array.new
  	problem_value = Array.new
  	problem_section = Array.new
  	sectionid = Array.new
  	n_section = Section.count
  	
  	(1..n_section).each do |i|
  		newpartial[i] = Array.new
  		existpartial[i] = Array.new
  	end
  	
  	User.all.each do |u|
  		newrating[u.id] = 0
  		(1..n_section).each do |i|
  			newpartial[i][u.id] = 0
  			existpartial[i][u.id] = false
  		end
  	end
  	
  	Pointspersection.all.each do |p|
  		existpartial[p.section_id][p.user_id] = true
  	end
  	
  	User.all.each do |u|
  		(1..n_section).each do |i|
  			if !existpartial[i][u.id]
  				newpoint = Pointspersection.new
       	 	newpoint.points = 0
        	newpoint.section_id = i
        	user.pointspersections << newpoint
  			end
  		end
  	end
  	
  	Chapter.all.each do |c|
    	sectionid[c.id] = c.section_id
    end
    
  	Exercise.all.each do |e|
  		exercise_value[e.id] = e.value
  		exercise_section[e.id] = sectionid[e.chapter_id]
  	end
  	
  	Qcm.all.each do |q|
  		qcm_value[q.id] = q.value
  		qcm_section[q.id] = sectionid[q.chapter_id]
  	end
  	
  	Problem.all.each do |p|
  		problem_value[p.id] = p.value
  		problem_section[p.id] = p.section_id
  	end
  	
  	Solvedexercise.all.each do |e|
  		if e.correct
        pt = exercise_value[e.exercise_id]
        u = e.user_id
        s = exercise_section[e.exercise_id]
        newrating[u] = newrating[u] + pt
        newpartial[s][u] = newpartial[s][u] + pt
  		end
  	end
  	
  	Solvedqcm.all.each do |q|
  		if q.correct
        pt = qcm_value[q.qcm_id]
        u = q.user_id
        s = qcm_section[q.qcm_id]
        newrating[u] = newrating[u] + pt
        newpartial[s][u] = newpartial[s][u] + pt
  		end
  	end
  	
  	Solvedproblem.all.each do |p|
  		pt = problem_value[p.problem_id]
  		u = p.user_id
  		s = problem_section[p.problem_id]
  		newrating[u] = newrating[u] + pt
      newpartial[s][u] = newpartial[s][u] + pt
  	end
  	
  	warning = ""
  	
  	Pointspersection.all.each do |p|
  		if newpartial[p.section_id][p.user_id] != p.points
  			p.points = newpartial[p.section_id][p.user_id]
  			p.save
  		end
  	end
  	
  	User.all.each do |u|
  		if newrating[u.id] != u.rating
  			warning = warning + "Le rating de #{u.name} a changé... "
  			u.rating = newrating[u.id]
  			u.save
  		end
  	end
  	
  	if(warning.size > 0)
  		flash[:danger] = warning
  	end
  end
	
	# Recalcule les scores de user
  def point_attribution(user)
    user.rating = 0
    partials = user.pointspersections
    partial = Array.new
    sectionid = Array.new

    Section.all.each do |s|
      partial[s.id] = partials.where(:section_id => s.id).first
      if partial[s.id].nil?
        newpoint = Pointspersection.new
        newpoint.points = 0
        newpoint.section_id = s.id
        user.pointspersections << newpoint
        partial[s.id] = user.pointspersections.where(:section_id => s.id).first
      end
      partial[s.id].points = 0
    end
    
    Chapter.all.each do |c|
    	sectionid[c.id] = c.section_id
    end

    user.solvedexercises.includes(:exercise).each do |e|
      if e.correct
        exo = e.exercise
        pt = exo.value
        user.rating = user.rating + pt
        partial[sectionid[exo.chapter_id]].points = partial[sectionid[exo.chapter_id]].points + pt
      end
    end

    user.solvedqcms.includes(:qcm).each do |q|
      if q.correct
        qcm = q.qcm
        pt = qcm.value
        user.rating = user.rating + pt
        partial[sectionid[qcm.chapter_id]].points = partial[sectionid[qcm.chapter_id]].points + pt
      end
    end

    user.solvedproblems.includes(:problem).each do |p|
      problem = p.problem
      pt = problem.value
      user.rating = user.rating + pt;
      partial[problem.section_id].points = partial[problem.section_id].points + pt
    end

    user.save
    Section.all.each do |s|
      partial[s.id].save
    end
  end
  
  # Gérer les pièces jointes
  def create_files
    attach = Array.new
    totalsize = 0
    
    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Myfile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          destroy_files(attach, i)
          nom = params["file#{k}".to_sym].original_filename
          @error = true
          @error_message = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          return [];
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    if totalsize > 5.megabytes
      destroy_files(attach, i)			
			@error = true
			@error_message = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/1.megabyte).round(3)} Mo)."
			return [];
    end
    
    return attach
  end
  
  def update_files(about, type)
  	totalsize = 0
  	about.myfiles.each do |f|
      if params["prevfile#{f.id}".to_sym].nil?
        f.file.destroy
        f.destroy
      else
        totalsize = totalsize + f.file_file_size
      end
    end

   	about.fakefiles.each do |f|
      if params["prevfakefile#{f.id}".to_sym].nil?
        f.destroy
      end
    end

    attach = Array.new

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Myfile.new(:file => params["file#{k}".to_sym])
        attach[i-1].myfiletable = about
        if !attach[i-1].save
        	destroy_files(attach, i)
          nom = params["file#{k}".to_sym].original_filename
          @error = true
          @error_message = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          return []
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    if totalsize > 5.megabytes
      destroy_files(attach, i)
      @error = true
      @error_message = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/1.megabyte).round(3)} Mo)"
      return []
    end
  end
  
  def destroy_files(attach, i)
  	j = 1
    while j < i do
      attach[j-1].file.destroy
      attach[j-1].destroy
      j = j+1
    end
  end
end
