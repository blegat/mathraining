#encoding: utf-8
class UsersController < ApplicationController
  before_action :signed_in_user, only: [:edit, :notifs_show, :groups, :read_legal, :followed_users, :remove_followingmessage]
  before_action :signed_in_user_danger, only: [:destroy, :destroydata, :update, :create_administrator, :take_skin, :leave_skin, :switch_wepion, :switch_corrector, :change_group, :add_followed_user, :remove_followed_user, :add_followingmessage, :switch_can_change_name, :ban_temporarily]
  before_action :admin_user, only: [:switch_wepion, :change_group]
  before_action :root_user, only: [:take_skin, :create_administrator, :destroy, :destroydata, :switch_corrector, :validate_names, :validate_name, :change_name, :switch_can_change_name, :ban_temporarily]
  before_action :signed_out_user, only: [:new, :create, :forgot_password, :password_forgotten]
  before_action :group_user, only: [:groups]
  
  before_action :get_user, only: [:edit, :update, :show, :destroy, :activate]
  before_action :get_user2, only: [:destroydata, :change_password, :take_skin, :create_administrator, :switch_wepion, :switch_corrector, :change_group, :recup_password, :add_followed_user, :remove_followed_user, :change_name, :switch_can_change_name, :ban_temporarily]
  
  before_action :correct_user, only: [:edit, :update]
  before_action :target_not_root, only: [:destroy, :destroydata]

  # Show all users with their scores
  def index
    @number_by_page = (Rails.env.test? ? 10 : 50) # For tests we put only 10 by page

    @country = 0
    if(params.has_key?:country)
      @country = params[:country].to_i
    end
    
    @real_users = true
    @title = 0
    @admin_users = false
    @min_rating = 1
    @max_rating = 1000000
    if(params.has_key?:title)
      @title = params[:title].to_i
      if @title >= 100
        @real_users = false
      elsif @title > 0
        cur_color = Color.find_by_id(@title)
        if cur_color.nil?
          @title = 0
        else
          @min_rating = [1, cur_color.pt].max
          next_color = Color.where("pt > ?", cur_color.pt).order("pt").first
          if !next_color.nil?
            @max_rating = next_color.pt - 1
          end
        end
      end
    end

    if !@real_users
      if @title == 100
        @min_rating = 0
        @max_rating = 0
        if @country == 0
          @all_users = User.where("rating = ? AND admin = ? AND active = ?", 0, false, true).order("id ASC")
        else
          @all_users = User.where("rating = ? AND admin = ? AND active = ? AND country_id = ?", 0, false, true, @country).order("id ASC")
        end
      elsif @title == 101
        @admin_users = true
        @min_rating = 0
        if @country == 0
          @all_users = User.where("admin = ? AND active = ?", true, true).order("id ASC")
        else
          @all_users = User.where("admin = ? AND active = ? AND country_id = ?", true, true, @country).order("id ASC")
        end
      end
      return
    end

    @page = 1
    if(params.has_key?:page)
      @page = params[:page].to_i
    end
    
    @allsec = Section.order(:id).where(:fondation => false).to_a

    @maxscore = Array.new

    Section.all.each do |s|
      @maxscore[s.id] = s.max_score
    end

    if @country == 0
      @all_users = User.where("rating <= ? AND rating >= ? AND admin = ? AND active = ?", @max_rating, @min_rating, false, true).order("rating DESC, id ASC").paginate(:page => @page, :per_page => @number_by_page)
    else
      @all_users = User.where("rating <= ? AND rating >= ? AND admin = ? AND active = ? AND country_id = ?", @max_rating, @min_rating, false, true, @country).order("rating DESC, id ASC").paginate(:page => @page, :per_page => @number_by_page)
    end

    num = @all_users.size
    @x_recent = Array.new(num)
    @x_persection = Array.new(num)
    @x_globalrank = Array.new(num)
    @x_country = Array.new(num)
    @x_rating = Array.new(num)
    @x_linked_name = Array.new(num)
    fill_user_info(@all_users, @x_recent, @x_persection, @x_globalrank, @x_rating, @x_country, @x_linked_name)
  end

  # Show all followed users
  def followed_users
    @allsec = Section.order(:id).where(:fondation => false).to_a

    @maxscore = Array.new

    Section.all.each do |s|
      @maxscore[s.id] = s.max_score
    end

    @all_users = current_user.sk.followed_users.where(:admin => false).to_a
    if !current_user.sk.admin?
      @all_users.append(current_user.sk)
    end
    @all_users.sort_by! { |u| [-u.rating, u.id] }
    num = @all_users.size
    @x_recent = Array.new(num)
    @x_persection = Array.new(num)
    @x_globalrank = Array.new(num)
    @x_country = Array.new(num)
    @x_rating = Array.new(num)
    @x_linked_name = Array.new(num)
    fill_user_info(@all_users, @x_recent, @x_persection, @x_globalrank, @x_rating, @x_country, @x_linked_name)
  end
  
  # Show one user
  def show
  end

  # Create a user, i.e. register on the website (show the form)
  def new
    @user = User.new
  end

  # Update a user (show the form)
  def edit
  end

  # Create a user, i.e. register on the website (send the form)
  def create
    @user = User.new(params.require(:user).permit(:first_name, :last_name, :see_name, :email, :email_confirmation, :sex, :year, :password, :password_confirmation, :accept_analytics))
    @user.key = SecureRandom.urlsafe_base64
    
    if(!params[:user][:country].nil? && params[:user][:country].to_i > 0)
      c = Country.find(params[:user][:country])
      @user.country = c
    end

    # Don't do e-mail and captcha in development and tests
    @user.email_confirm = !Rails.env.production?
    
    # Remove white spaces at start and end, and add '.' if needed
    @user.adapt_name
    
    if !params.has_key?("consent1") || !params.has_key?("consent2")
      flash.now[:danger] = "Vous devez accepter notre politique de confidentialité pour pouvoir créer un compte."
      render 'new'
    elsif (not Rails.env.production? or verify_recaptcha(:model => @user, :message => "Captcha incorrect")) && @user.save
      UserMailer.registration_confirmation(@user.id).deliver
      
      user_reload = User.find(@user.id) # Reload because email and email_confirmation can be different after downcaise otherwise!
      user_reload.consent_time = DateTime.now
      user_reload.last_policy_read = true
      user_reload.save
      
      flash[:success] = "Vous allez recevoir un e-mail de confirmation d'ici quelques minutes pour activer votre compte. Vérifiez votre courrier indésirable si celui-ci semble ne pas arriver. Vous avez 7 jours pour confirmer votre inscription. Si vous rencontrez un problème, alors n'hésitez pas à contacter l'équipe Mathraining (voir 'Contact', en bas à droite de la page)."
      redirect_to root_path
    else
      render 'new'
    end
  end

  # Update a user (send the form)
  def update
    old_last_name = @user.last_name
    old_first_name = @user.first_name

    if @user.update(params.require(:user).permit(:first_name, :last_name, :see_name, :sex, :year, :password, :password_confirmation, :email, :accept_analytics))
      c = Country.find(params[:user][:country])
      @user.update_attribute(:country, c)
      if !@user.can_change_name && !current_user.root?
        @user.last_name = old_last_name
        @user.first_name = old_first_name
      end
      @user.adapt_name
      @user.save
      flash[:success] = "Votre profil a bien été mis à jour."
      if(current_user.root? and current_user.other)
        @user.update_attribute(:valid_name, true)
        current_user.update_attribute(:skin, 0)
        redirect_to validate_names_path
      else
        if((old_last_name != @user.last_name || old_first_name != @user.first_name) && !current_user.sk.admin)
          @user.update_attribute(:valid_name, false)
        end
        redirect_to root_path
      end
    else
      render 'edit'
    end
  end

  # Delete a user
  def destroy
    remove_skins(@user)
    @user.destroy
    flash[:success] = "Utilisateur supprimé."
    redirect_to @user
  end

  # Mark user as administrator
  def create_administrator
    @user.admin = true
    @user.save
    remove_skins(@user)
    flash[:success] = "Utilisateur promu au rang d'administrateur !"
    redirect_to @user
  end

  # Add or remove a user from Wépion group
  def switch_wepion
    if !@user.admin?
      if @user.wepion
        flash[:success] = "Utilisateur retiré du groupe Wépion."
        @user.group = ""
        @user.save
      else
        flash[:success] = "Utilisateur ajouté au groupe Wépion."
      end
      @user.toggle!(:wepion)
    end
    redirect_to @user
  end

  # Add or remove a user from correctors
  def switch_corrector
    if !@user.admin?
      if !@user.corrector
        flash[:success] = "Utilisateur ajouté aux correcteurs."
      else
        flash[:success] = "Utilisateur retiré des correcteurs."
      end
      @user.toggle!(:corrector)
    end
    redirect_to @user
  end
  
  # Forbid or allow a user to change his name
  def switch_can_change_name
    if @user.can_change_name
      flash[:success] = "Cet utilisateur ne peut maintenant plus changer son nom."
    else
      flash[:success] = "Cet utilisateur peut à nouveau changer son nom."
    end
    @user.toggle!(:can_change_name)
    redirect_to @user
  end
  
  # Deactivate the account for two weeks (because of plagiarism)
  def ban_temporarily
    unless @user.is_banned
      @user.update_attribute(:last_ban_date, DateTime.now)
      @user.update_remember_token # sign out the user
      flash[:success] = "Cet utilisateur a été banni jusqu'au #{write_date(@user.end_of_ban)}."
    end
    redirect_to @user
  end

  # Change the Wépion group of a user
  def change_group
    g = params[:group]
    @user.group = g
    @user.save
    flash[:success] = "Utilisateur changé de groupe."
    redirect_to @user
  end

  # Activate an account
  def activate
    if !@user.email_confirm && @user.key.to_s == params[:key].to_s
      @user.toggle!(:email_confirm)
      flash[:success] = "Votre compte a bien été activé ! Veuillez maintenant vous connecter."
    elsif @user.key.to_s != params[:key].to_s
      flash[:danger] = "Le lien d'activation est erroné."
    else
      flash[:info] = "Ce compte est déjà actif !"
    end
    redirect_to root_path
  end
  
  # Password forgotten: first page
  def forgot_password
  end

  # Password forgotten: check captcha and send email
  def password_forgotten
    @user = User.new
    render 'forgot_password' and return if (Rails.env.production? and !verify_recaptcha(:model => @user, :message => "Captcha incorrect"))

    @user = User.where(:email => params[:user][:email]).first
    if @user
      if @user.email_confirm
        @user.update_attribute(:key, SecureRandom.urlsafe_base64)
        @user.update_attribute(:recup_password_date_limit, DateTime.now)
        UserMailer.forgot_password(@user.id).deliver
        flash[:info] = "Lien (développement uniquement) : localhost:3000/users/#{@user.id}/recup_password?key=#{@user.key}" if !Rails.env.production?
        flash[:success] = "Vous allez recevoir un e-mail d'ici quelques minutes pour que vous puissiez changer de mot de passe. Vérifiez votre courrier indésirable si celui-ci semble ne pas arriver."
      else
        flash[:danger] = "Veuillez d'abord confirmer votre adresse e-mail à l'aide du lien qui vous a été envoyé à l'inscription. Si vous n'avez pas reçu cet e-mail, alors n'hésitez pas à contacter l'équipe Mathraining (voir 'Contact', en bas à droite de la page)."
      end
    else
      flash[:danger] = "Aucun utilisateur ne possède cette adresse."
    end
    redirect_to root_path
  end

  # Password forgotten: page to change password (we arrive here from email)
  def recup_password  
    if @user.nil? || @user.key.to_s != params[:key].to_s || @user.recup_password_date_limit.nil?
      flash[:danger] = "Ce lien n'est pas valide (ou a déjà été utilisé)."
      redirect_to root_path
    elsif DateTime.now > @user.recup_password_date_limit + 3600
      flash[:danger] = "Ce lien n'est plus valide (il expirait après une heure). Veuillez en redemander un autre."
      redirect_to root_path
    else
      # If the "signed_out" parameter is not there than we add it
      # This is to avoid the problem that occurs when somebody tries to connect from this page
      # Indeed when we connect, we are redirected to the previous page, and this page automatically disconnects the user
      if(params[:signed_out].nil?)
        if @signed_in
          sign_out
        end
        redirect_to user_recup_password_path(@user, :key => @user.key, :signed_out => 1)
      elsif @signed_in
        # If the "signed_out" is present and we are connected, it means that we just connected
        redirect_to root_path
      end
    end
  end
  
  # Password forgotten: check and set new password
  def change_password
    if (@user.nil? || @user.key.to_s != params[:key].to_s || @user.recup_password_date_limit.nil?)
      flash[:danger] = "Une erreur est survenue. Il semble que votre lien pour changer de mot de passe ne soit plus valide."
      redirect_to root_path
    elsif DateTime.now > @user.recup_password_date_limit + 3600
      flash[:danger] = "Vous avez mis trop de temps à modifier votre mot de passe. Veuillez réitérer votre demande de changement de mot de passe."
      redirect_to root_path
    else
      if (params[:user][:password].nil? or params[:user][:password].length == 0)
        session["errorChange"] = ["Mot de passe est vide"]
        redirect_to user_recup_password_path(@user, :key => @user.key, :signed_out => 1)
      elsif (not Rails.env.production? or verify_recaptcha(:model => @user, :message => "Captcha incorrect")) && @user.update(params.require(:user).permit(:password, :password_confirmation))
        @user.update_attribute(:key, SecureRandom.urlsafe_base64)
        @user.update_attribute(:recup_password_date_limit, nil)
        flash[:success] = "Votre mot de passe vient d'être modifié. Vous pouvez maintenant vous connecter à votre compte."
        redirect_to root_path
      else
        session["errorChange"] = @user.errors.full_messages
        redirect_to user_recup_password_path(@user, :key => @user.key, :signed_out => 1)
      end
    end
  end

  # Show notifications of new corrections (for a student)
  def notifs_show
    @notifs = current_user.sk.notifs.order("created_at")
    render :notifs
  end

  # Take the skin of a user
  def take_skin
    unless @user.admin || !@user.active # Cannot take the skin of an admin or inactive user
      current_user.update_attribute(:skin, @user.id)
      flash[:success] = "Vous êtes maintenant dans la peau de #{@user.name}."
    end
    redirect_back(fallback_location: root_path)
  end

  # Leave the skin of a user
  def leave_skin
    if current_user.id == params[:user_id].to_i
      current_user.update_attribute(:skin, 0)
      flash[:success] = "Vous êtes à nouveau dans votre peau."
    end
    redirect_back(fallback_location: root_path)
  end

  # Deletes data of one account
  def destroydata
    if @user.active
      flash[:success] = "Les données personnelles de #{@user.name} ont été supprimées."
      @user.active = false
      @user.email = @user.id.to_s
      @user.first_name = "Compte"
      @user.last_name = "supprimé"
      @user.see_name = 1
      @user.wepion = false
      @user.valid_name = true
      @user.follow_message = false
      @user.rating = 0
      @user.save
      @user.followingsubjects.each do |f|
        f.destroy
      end
      @user.followingcontests.each do |f|
        f.destroy
      end
      @user.followingusers.each do |f|
        f.destroy
      end
      @user.backwardfollowingusers.each do |f|
        f.destroy
      end
      remove_skins(@user)
      @user.update_remember_token # sign out the user
    end
    redirect_to root_path
  end

  # Show Wépion groups
  def groups
  end

  # Show correctors (and some statistics)
  def correctors
  end
  
  # Show all names to validate
  def validate_names
    @users_to_validate = User.where(:valid_name => false, :email_confirm => true, :admin => false).order("id DESC").all
  end
  
  # Validate one name (through js)
  def validate_name
    u = User.find(params[:userid].to_i)
    suggestion = params[:suggestion].to_i
    if !u.nil?
      u.valid_name = true
      if suggestion == 1
        u.first_name = u.first_name.my_titleize
        u.last_name = u.last_name.my_titleize
      end
      u.save
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  # Link to change one user name
  def change_name
    current_user.update_attribute(:skin, @user.id)
    redirect_to edit_user_path(@user)
  end
  
  # Page to read last privacy policy
  def read_legal
  end
  
  # Accept last privacy policy
  def accept_legal
    if !params.has_key?("consent1") || !params.has_key?("consent2")
      flash.now[:danger] = "Vous devez accepter notre politique de confidentialité pour pouvoir continuer sur le site."
      render 'read_legal'
    else
      user = current_user
      user.consent_time = DateTime.now
      user.last_policy_read = true
      user.save
      redirect_to root_path
    end
  end

  # Start following a user
  def add_followed_user
    unless current_user.sk == @user or current_user.sk.followed_users.exists?(@user.id) or @user.admin?
      if current_user.sk.followed_users.size >= 30
        flash[:danger] = "Vous ne pouvez pas suivre plus de 30 utilisateurs."
      else
        current_user.sk.followed_users << @user
        flash[:success] = "Vous suivez maintenant #{ @user.name }."
      end
    end
    redirect_to @user
  end

  # Stop following a user
  def remove_followed_user
    current_user.sk.followed_users.destroy(@user)
    flash[:success] = "Vous ne suivez plus #{ @user.name }."
    redirect_to @user
  end

  # Start receiving emails for new tchatmessages
  def add_followingmessage
    current_user.sk.follow_message = true
    current_user.sk.save
    
    flash[:success] = "Vous recevrez dorénavant un e-mail à chaque nouveau message privé."
    redirect_back(fallback_location: new_discussion_path)
  end

  # Stop receiving emails for new tchatmessages
  def remove_followingmessage
    current_user.sk.follow_message = false
    current_user.sk.save
    
    flash[:success] = "Vous ne recevrez maintenant plus d'e-mail lors d'un nouveau message privé."
    redirect_back(fallback_location: new_discussion_path)
  end

  private
  
  ########## GET METHODS ##########

  # Get the user
  def get_user
    @user = User.find_by_id(params[:id])
    if @user.nil? || !@user.active?
      render 'errors/access_refused' and return
    end
  end
  
  # Get the user 2
  def get_user2
    @user = User.find_by_id(params[:user_id])
    if @user.nil? || !@user.active?
      render 'errors/access_refused' and return
    end
  end
  
  ########## CHECK METHODS ##########
  
  # Check that current user is in some Wépion group
  def group_user
    if !current_user.sk.admin && current_user.sk.group == ""
      render 'errors/access_refused' and return
    end
  end
  
  # Check that the targer user is current user
  def correct_user
    if current_user.sk.id != @user.id
      render 'errors/access_refused' and return
    end
  end
  
  # Check that the target user is not a root
  def target_not_root
    if @user.root?
      render 'errors/access_refused' and return
    end
  end
  
  ########## HELPER METHODS ##########
  
  # Helper method to make everybody with some skin leaves this skin
  def remove_skins(user)
    User.where(skin: @user.id).each do |u|
      u.update_attribute(:skin, 0)
    end
  end
  
  # Helper method to fill informations for a set of users (for ranking page)
  def fill_user_info(users, recent, persection, globalrank, rating, country, linked_name)
    global_user_id_to_local_id = Array.new((User.last.nil? ? 0 : User.last.id) + 1)

    ids = Array.new(users.size)
    local_id = 0
    
    globalrank_here = User.select("users.id, (SELECT COUNT(u.id) FROM users AS u WHERE u.rating > users.rating AND u.admin = #{false_value_sql} AND u.active = #{true_value_sql}) + 1 AS ranking").where(:id => users.map(&:id)).order("rating DESC").to_a.map(&:ranking)

    users.each do |u|
      ids[local_id] = u.id
      global_user_id_to_local_id[u.id] = local_id
      persection[local_id] = Array.new
      recent[local_id] = 0
      rating[local_id] = u.rating
      globalrank[local_id] = globalrank_here[local_id]
      country[local_id] = u.country_id
      linked_name[local_id] = u.linked_name
      local_id = local_id + 1
    end

    # Sort users with rank 1 in random order (only if at least 2 people with rank 1)
    if local_id >= 2 and globalrank[1] == 1
      s = 2
      while s < local_id and globalrank[s] == 1
        s = s + 1
      end
      r = Random.new(Date.today.in_time_zone.to_time.to_i)
      alea = Array.new(s)
      (0..(s-1)).each do |i|
        x = r.rand()
        if @signed_in and ids[i] == current_user.sk.id
          alea[i] = [0, i]
        else
          alea[i] = [x, i]
        end
      end
      alea.sort!
      save_ids = Array.new(s)
      save_country = Array.new(s)
      save_linked_name = Array.new(s)
      (0..(s-1)).each do |i|
        save_ids[i] = ids[i]
        save_country[i] = country[i]
        save_linked_name[i] = linked_name[i]
      end
      (0..(s-1)).each do |i|
        ids[i] = save_ids[alea[i][1]]
        country[i] = save_country[alea[i][1]]
        linked_name[i] = save_linked_name[alea[i][1]]
        global_user_id_to_local_id[ids[i]] = i
      end
    end

    twoweeksago = Date.today - 14

    Solvedproblem.where(:user_id => ids).includes(:problem).where("resolution_time > ?", twoweeksago).find_each do |s|
      recent[global_user_id_to_local_id[s.user_id]] += s.problem.value
    end

    Solvedquestion.where(:user_id => ids).includes(:question).where("resolution_time > ? AND correct = ?", twoweeksago, true).find_each do |s|
      recent[global_user_id_to_local_id[s.user_id]] += s.question.value
    end

    Pointspersection.where(:user_id => ids).all.each do |p|
	    persection[global_user_id_to_local_id[p.user_id]][p.section_id] = p.points
    end
  end  
end
