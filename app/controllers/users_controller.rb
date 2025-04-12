#encoding: utf-8
class UsersController < ApplicationController
  skip_before_action :user_has_some_actions_to_take, only: [:improve_password, :accept_legal, :accept_code_of_conduct]
  
  before_action :signed_in_user, only: [:edit, :notifs, :groups, :followed, :unset_follow_message, :search]
  before_action :signed_in_user_danger, only: [:destroy, :destroydata, :update, :set_administrator, :take_skin, :leave_skin, :set_wepion, :unset_wepion, :set_corrector, :unset_corrector, :change_group, :accept_legal, :accept_code_of_conduct, :follow, :unfollow, :set_follow_message, :validate_names, :validate_name, :change_name, :set_can_change_name, :unset_can_change_name, :improve_password]
  before_action :admin_user, only: [:set_wepion, :unset_wepion, :change_group]
  before_action :root_user, only: [:take_skin, :set_administrator, :destroy, :destroydata, :set_corrector, :unset_corrector, :validate_names, :validate_name, :change_name, :set_can_change_name, :unset_can_change_name]
  before_action :signed_out_user, only: [:new, :create, :forgot_password, :password_forgotten]
  before_action :group_user, only: [:groups]
  
  before_action :get_user, only: [:edit, :update, :show, :destroy, :activate, :destroydata, :change_password, :take_skin, :set_administrator, :set_wepion, :unset_wepion, :set_corrector, :unset_corrector, :change_group, :recup_password, :follow, :unfollow, :validate_name, :change_name, :set_can_change_name, :unset_can_change_name]
  
  before_action :avoid_strange_scraping, only: [:index]
  
  before_action :target_user_is_current_user, only: [:edit, :update]
  before_action :target_user_is_not_root, only: [:destroy, :destroydata]

  # Show all users with their scores
  def index
    number_by_page = (Rails.env.production? ? 50 : 10) # For tests and development we put only 10 by page

    @country = 0
    if params.has_key?:country
      @country = params[:country].to_i
    end
    
    page = 1
    if params.has_key?:page
      page = params[:page].to_i
    end
    
    @real_users = true
    @title = 0
    @min_rating = 1
    @max_rating = 1000000
    @admin = false
    if(params.has_key?:title)
      @title = params[:title].to_i
      if @title == -1
        @real_users = false
        @min_rating = 0
        @max_rating = 0
      elsif @title == -2
        @real_users = false
        @min_rating = 0
        @admin = true
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
    
    rating_condition = (@min_rating == 0 && @max_rating == 1000000 ? "1=1" : "rating <= #{@max_rating} AND rating >= #{@min_rating}")
    @num_users_in_rating_range_by_country = User.where(:role => (@admin ? [:administrator, :root] : [:student])).where("#{rating_condition}").group(:country_id).count
    
    country_condition = (@country == 0 ? "1=1" : "country_id = #{@country}")
    @num_users_in_country_by_rating =  User.where(:role => :student).where("rating > 0 AND #{country_condition}").group(:rating).order("rating DESC").count

    if !@real_users
      if @title == -1
        @all_users = User.where(:role => :student).where("rating = 0 AND #{country_condition}").order("id ASC")
      elsif @title == -2
        @all_users = User.where(:role => [:administrator, :root]).where("#{country_condition}").order("id ASC")
      end
      return
    end
    
    fill_sections_max_score
    
    all_users_count = (@country == 0 ? @num_users_in_rating_range_by_country.sum{|x| x.second} : @num_users_in_rating_range_by_country[@country])
    @all_users = User.where(:role => :student).where("#{rating_condition} AND #{country_condition}").order("rating DESC, id ASC").paginate(:page => page, :per_page => number_by_page, :total_entries => all_users_count)

    fill_user_info(@all_users)
  end

  # Show all followed users
  def followed
    fill_sections_max_score
    
    @all_users = current_user.followed_users.where(:role => :student).to_a
    if !current_user.admin?
      @all_users.append(current_user)
    end
    @all_users.sort_by! { |u| [-u.rating, u.id] }
    
    fill_user_info(@all_users)
  end
  
  # Search for users by name
  def search
    return unless params.has_key?:search
    
    search = params[:search].dup # real copy
    
    (0..(search.size-1)).each do |i|
      if !User.allowed_characters.include?(search[i]) && !User.allowed_special_characters.include?(search[i])
        @search_error = "Le caractère #{search[i]} n'est pas autorisé dans le nom des utilisateurs."
        return
      end
    end
    
    # Remove leading and trailing white spaces
    while search[0] == ' '
      search = search.slice(1..-1)
    end
    
    while search[search.size-1] == ' '
      search = search.slice(0..-2)
    end
    
    # Remove wrong double spaces
    search = search.gsub("  ", " ") while search != search.gsub("  ", " ")
    
    number_by_page = (Rails.env.test? ? 2 : 50)
    page = 1
    if params.has_key?:page
      page = params[:page].to_i
    end
    
    if search.size < 3
      @search_error = "Au moins 3 caractères sont nécessaires."
      return
    end
    
    # Replace ' by '' for SQL query to work
    search.gsub!(/[']/, "''")
    
    fill_sections_max_score
    
    name_condition = "(see_name = 1 AND LOWER(first_name || ' ' || last_name) LIKE LOWER('%#{search}%')) OR (see_name = 0 AND LOWER(first_name || ' ' || SUBSTR(last_name, 1, 1) || '.') LIKE LOWER('%#{search}%'))"
    @all_users = User.where(:role => :student).where(name_condition).order("rating DESC, id ASC").paginate(:page => page, :per_page => number_by_page)
    @admin_users = (page == 1 ? User.where(:role => [:administrator, :root]).where(name_condition).order("first_name, last_name").to_a : [])
    
    fill_user_info(@all_users)
  end
  
  # Show one user
  def show
  end

  # Create a user, i.e. register on the website (show the form)
  def new
    flash.now[:info] = @temporary_closure_message if @temporary_closure
    @show_code_of_conduct = !(Rails.env.test? && params.has_key?("hide_code_of_conduct"))
    @user = User.new
  end

  # Update a user (show the form)
  def edit
  end

  # Create a user, i.e. register on the website (send the form)
  def create
    redirect_to root_path and return if @temporary_closure
    @user = User.new(params.require(:user).permit(:first_name, :last_name, :see_name, :email, :email_confirmation, :sex, :year, :country_id, :password, :password_confirmation, :accept_analytics))
    @user.key = SecureRandom.urlsafe_base64
    @user.email_confirm = false
    @user.adapt_name # Remove white spaces at start and end, and add '.' if needed
    
    @show_code_of_conduct = false
    if !params.has_key?("consent1") || !params.has_key?("consent2")
      flash.now[:danger] = "Vous devez accepter notre politique de confidentialité pour pouvoir créer un compte."
      render 'new'
    elsif (Rails.env.test? || Rails.env.development? || verify_recaptcha(:model => @user, :message => "Captcha incorrect")) && @user.save
      UserMailer.registration_confirmation(@user.id).deliver
      
      @user.update(:consent_time => DateTime.now, :last_policy_read => true, :accepted_code_of_conduct => true)
      
      flash[:info] = "Lien (développement uniquement) : localhost:3000/activate?id=#{@user.id}&key=#{@user.key}" if !Rails.env.production?
      flash[:success] = "Vous allez recevoir un e-mail de confirmation d'ici quelques minutes pour activer votre compte. Vérifiez votre courrier indésirable si celui-ci semble ne pas arriver. Vous avez 7 jours pour confirmer votre inscription. Si vous rencontrez un problème, alors n'hésitez pas à contacter l'équipe Mathraining (voir 'Contact', en bas de la page)."
      redirect_to root_path
    else
      render 'new'
    end
  end

  # Update a user (send the form)
  def update
    old_last_name = @user.last_name
    old_first_name = @user.first_name

    allowed_params = [:see_name, :sex, :year, :country_id, :password, :password_confirmation, :accept_analytics]
    allowed_params << [:first_name, :last_name] unless !@user.can_change_name && !in_skin?
    allowed_params << :email if current_user_no_skin.admin? # no_skin because root can change email of someone else
    allowed_params << :corrector_color if (current_user.admin? || current_user.corrector?)
    if @user.update(params.require(:user).permit(allowed_params))
      @user.adapt_name
      @user.save
      flash[:success] = "Votre profil a bien été mis à jour."
      if ((old_last_name != @user.last_name || old_first_name != @user.first_name) && !current_user.root?)
        @user.update_attribute(:valid_name, false)
      end
      redirect_to edit_user_path(@user)
    else       
      render 'edit'
    end
  end

  # Delete a user
  def destroy
    if @user.messages.count > 0 || @user.submissions.count > 0 || @user.contestsolutions.count > 0 || @user.puzzleattempts.count > 0
      m = "Cet utilisateur ne peut pas être totalement supprimé car il a :<ul>"
      m += "<li>#{@user.messages.count} messages sur le Forum</li>" if @user.messages.count > 0
      m += "<li>#{@user.submissions.count} soumissions à un problème</li>" if @user.submissions.count > 0
      m += "<li>#{@user.contestsolutions.count} solutions à un problème de Concours</li>" if @user.contestsolutions.count > 0
      m += "<li>#{@user.puzzleattempts.count} tentatives de résolution d'énigme</li>" if @user.puzzleattempts.count > 0
      m += "</ul>Vous pouvez par contre supprimer ses données personnelles."
      flash[:danger] = m
      redirect_to @user and return
    end
    
    remove_skins(@user)
    @user.destroy
    Globalstatistic.get.update_all
    flash[:success] = "Utilisateur supprimé."
    redirect_to @user
  end

  # Mark user as administrator
  def set_administrator
    @user.update_attribute(:role, :administrator)
    remove_skins(@user)
    flash[:success] = "Utilisateur promu au rang d'administrateur !"
    redirect_to @user
  end

  # Add a user to Wépion group
  def set_wepion
    if !@user.admin?
      flash[:success] = "Utilisateur ajouté au groupe Wépion."
      @user.update_attribute(:wepion, true)
    end
    redirect_to @user
  end
  
  # Remove a user from Wépion group
  def unset_wepion
    if !@user.admin?
      flash[:success] = "Utilisateur retiré du groupe Wépion."
      @user.update(:wepion => false, :group => "")
    end
    redirect_to @user
  end

  # Add a user to correctors
  def set_corrector
    if !@user.admin?
      flash[:success] = "Utilisateur ajouté aux correcteurs."
      @user.update(:corrector => true)
    end
    redirect_to @user
  end
  
  # Remove a user from correctors
  def unset_corrector
    if !@user.admin?
      flash[:success] = "Utilisateur retiré des correcteurs."
      @user.update(:corrector => false)
    end
    redirect_to @user
  end
  
  # Allow a user to change his name
  def set_can_change_name
    flash[:success] = "Cet utilisateur peut à nouveau changer son nom."
    @user.update_attribute(:can_change_name, true)
    redirect_to @user
  end
  
  # Forbid a user to change his name
  def unset_can_change_name
    flash[:success] = "Cet utilisateur ne peut maintenant plus changer son nom."
    @user.update_attribute(:can_change_name, false)
    redirect_to @user
  end

  # Change the Wépion group of a user
  def change_group
    @user.update_attribute(:group, params[:group])
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
    render 'forgot_password' and return if (!Rails.env.test? && !Rails.env.development? && !verify_recaptcha(:model => @user, :message => "Captcha incorrect"))

    @user = User.where(:email => params[:user][:email]).first
    if @user.nil?
      flash.now[:danger] = "Aucun utilisateur ne possède cette adresse."
      render 'forgot_password' and return
    end
    
    if @user.email_confirm
      @user.update_attribute(:key, SecureRandom.urlsafe_base64)
      @user.update_attribute(:recup_password_date_limit, DateTime.now)
      UserMailer.forgot_password(@user.id).deliver
      flash[:info] = "Lien (développement uniquement) : localhost:3000/users/#{@user.id}/recup_password?key=#{@user.key}" if !Rails.env.production?
      flash[:success] = "Vous allez recevoir un e-mail d'ici quelques minutes pour que vous puissiez changer de mot de passe. Vérifiez votre courrier indésirable si celui-ci semble ne pas arriver."
    else
      flash[:danger] = "Veuillez d'abord confirmer votre adresse e-mail à l'aide du lien qui vous a été envoyé à l'inscription. Si vous n'avez pas reçu cet e-mail, alors n'hésitez pas à contacter l'équipe Mathraining (voir 'Contact', en bas à droite de la page)."
    end
    redirect_to root_path
  end

  # Password forgotten: page to change password (we arrive here from email)
  def recup_password  
    if @user.nil? || @user.key.to_s != params[:key].to_s || @user.recup_password_date_limit.nil?
      flash[:danger] = "Ce lien n'est pas valide (ou a déjà été utilisé)."
      redirect_to root_path and return
    elsif DateTime.now > @user.recup_password_date_limit + (Puzzle.started_or_root(@user) ? 4500.seconds : 3600.seconds)
      flash[:danger] = "Ce lien n'est plus valide (il expirait après une heure). Veuillez en redemander un autre."
      redirect_to root_path and return
    else
      # If the "signed_out" parameter is not there than we add it
      # This is to avoid the problem that occurs when somebody tries to connect from this page
      # Indeed when we connect, we are redirected to the previous page, and this page automatically disconnects the user
      if(params[:signed_out].nil?)
        if signed_in?
          sign_out
        end
        redirect_to recup_password_user_path(@user, :key => @user.key, :signed_out => 1) and return
      elsif signed_in?
        # If the "signed_out" is present and we are connected, it means that we just connected
        redirect_to root_path and return
      end
    end
  end
  
  # Password forgotten: check and set new password
  def change_password
    if (@user.nil? || @user.key.to_s != params[:key].to_s || @user.recup_password_date_limit.nil?)
      flash[:danger] = "Une erreur est survenue. Il semble que votre lien pour changer de mot de passe ne soit plus valide."
      redirect_to root_path
    elsif DateTime.now > @user.recup_password_date_limit + (Puzzle.started_or_root(@user) ? 4500.seconds : 3600.seconds)
      flash[:danger] = "Vous avez mis trop de temps à modifier votre mot de passe. Veuillez réitérer votre demande de changement de mot de passe."
      redirect_to root_path
    else
      if DateTime.now > @user.recup_password_date_limit + 3600.seconds && check_typo_error(params[:user][:password], params[:user][:password_confirmation])
        @user.update(:key => SecureRandom.urlsafe_base64, :recup_password_date_limit => nil)
        flash[:info] = "Je ne vous félicite pas : vous avez une mauvaise mémoire, vous êtes en retard et vous tapez trop vite ! Quel personnage, ami de Malika, a également l'un ces défauts ?"
        redirect_to root_path
      elsif (params[:user][:password].nil? || params[:user][:password].length == 0)
        @user.errors.add(:base, "Mot de passe est vide")
        render 'recup_password'
      elsif @user.update(params.require(:user).permit(:password, :password_confirmation))
        @user.update(:key => SecureRandom.urlsafe_base64, :recup_password_date_limit => nil)
        flash[:success] = "Votre mot de passe a été modifié avec succès. Vous pouvez maintenant vous connecter à votre compte."
        redirect_to root_path
      else
        render 'recup_password'
      end
    end
  end
  
  # Password too weak: check and set new password
  def improve_password
    if (params[:user][:password].nil? || params[:user][:password].length == 0)
      current_user_no_skin.errors.add(:base, "Mot de passe est vide")
      render 'set_strong_password'
    elsif current_user_no_skin.update(params.require(:user).permit(:password, :password_confirmation))
      current_user_no_skin.strong_password!
      flash[:success] = "Votre mot de passe a été modifié avec succès."
      redirect_to root_path
    else
      render 'set_strong_password'
    end
  end

  # Show notifications of new corrections (for a student)
  def notifs
    @notified_submissions = current_user.notified_submissions.order("last_comment_time")
  end

  # Take the skin of a user
  def take_skin
    if @user.student? # Cannot take the skin of an admin or a deleted user
      current_user_no_skin.update_attribute(:skin, @user.id)
      flash[:success] = "Vous êtes maintenant dans la peau de #{@user.name}."
    end
    redirect_back(fallback_location: root_path)
  end

  # Leave the skin of a user
  def leave_skin
    if current_user_no_skin.skin != 0
      current_user_no_skin.update_attribute(:skin, 0)
      flash[:success] = "Vous êtes à nouveau dans votre peau."
    end
    redirect_back(fallback_location: root_path)
  end

  # Deletes data of one account
  def destroydata
    unless @user.deleted?
      flash[:success] = "Les données personnelles de #{@user.name} ont été supprimées."
      @user.update(:role           => :deleted,
                   :email          => "deleted-" + @user.id.to_s + "@deleted.com",
                   :first_name     => "Compte",
                   :last_name      => "supprimé",
                   :see_name       => 1,
                   :wepion         => false,
                   :valid_name     => true,
                   :follow_message => false,
                   :rating         => 0)
      @user.followed_subjects.clear
      @user.followed_contests.clear
      @user.followed_users.clear
      @user.following_users.clear
      @user.notified_submissions.clear
      remove_skins(@user)
      @user.update_remember_token # sign out the user
      Globalstatistic.get.update_all
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
    @users_to_validate = User.where(:valid_name => false, :email_confirm => true).order("id DESC").all
  end
  
  # Validate one name (through js)
  def validate_name
    if params.has_key?(:suggestion)
      suggestion = params[:suggestion].to_i
      if suggestion == 1
        @user.first_name = @user.first_name.my_titleize
        @user.last_name = @user.last_name.my_titleize
      elsif suggestion == 2
        @user.first_name = @user.first_name[0].upcase + "."
        @user.last_name = @user.last_name[0].upcase + "."
      end
      @user.adapt_name
      @user.valid_name = true
      @user.save
    elsif params.has_key?(:first_name) && params.has_key?(:last_name)
      @user.first_name = params[:first_name]
      @user.last_name = params[:last_name]
      @user.adapt_name
      @user.valid_name = true
      @user.save
    end
    respond_to :js
  end
  
  # Accept last privacy policy
  def accept_legal
    if !params.has_key?("consent1") || !params.has_key?("consent2")
      flash.now[:danger] = "Vous devez accepter notre politique de confidentialité pour pouvoir continuer sur le site."
      render 'read_legal'
    else
      current_user_no_skin.update(:last_policy_read => true, :consent_time => DateTime.now)
      redirect_to root_path
    end
  end
  
  # Accept code of conduct
  def accept_code_of_conduct
    current_user_no_skin.update_attribute(:accepted_code_of_conduct, true)
    redirect_to root_path
  end

  # Start following a user
  def follow
    unless current_user == @user || current_user.followed_users.exists?(@user.id) || @user.admin?
      if current_user.followed_users.size >= 30
        flash[:danger] = "Vous ne pouvez pas suivre plus de 30 utilisateurs."
      else
        current_user.followed_users << @user
        flash[:success] = "Vous suivez maintenant #{ @user.name }."
      end
    end
    redirect_to @user
  end

  # Stop following a user
  def unfollow
    current_user.followed_users.destroy(@user)
    flash[:success] = "Vous ne suivez plus #{ @user.name }."
    redirect_to @user
  end

  # Start receiving emails for new tchatmessages
  def set_follow_message
    current_user.update_attribute(:follow_message, true)
    
    flash[:success] = "Vous recevrez dorénavant un e-mail à chaque nouveau message privé."
    redirect_back(fallback_location: new_discussion_path)
  end

  # Stop receiving emails for new tchatmessages
  def unset_follow_message
    current_user.update_attribute(:follow_message, false)
    
    flash[:success] = "Vous ne recevrez maintenant plus d'e-mail lors d'un nouveau message privé."
    redirect_back(fallback_location: new_discussion_path)
  end

  private
  
  ########## GET METHODS ##########

  # Get the user
  def get_user
    @user = User.find_by_id(params[:id])
    if @user.nil? || @user.deleted?
      render 'errors/access_refused'
    end
  end
  
  ########## CHECK METHODS ##########
  
  # Check that current user is in some Wépion group
  def group_user
    if !current_user.admin? && current_user.group == ""
      render 'errors/access_refused'
    end
  end
  
  # Check that the target user is current user
  def target_user_is_current_user
    if current_user.id != @user.id
      render 'errors/access_refused'
    end
  end
  
  # Check that the target user is not a root
  def target_user_is_not_root
    if @user.root?
      render 'errors/access_refused'
    end
  end
  
  # Some scrapers require 'index' every second with random parameters 'page', 'from' and 'rank' (???)
  def avoid_strange_scraping
    if params.has_key?(:from) || params.has_key?(:rank)
      render 'errors/access_refused'
    end
  end
  
  ########## HELPER METHODS ##########
  
  def check_typo_error(password, password_confirmation)
    return false if password.nil? || password_confirmation.nil?
    return false if password.size < 6
    return false if password == password_confirmation # Important!
    n = password.size
    if password_confirmation.size == n
      # Swap two consecutive characters
      (0..(n-2)).each do |i|
        possible_confirmation = password.clone
        possible_confirmation[i] = password[i+1]
        possible_confirmation[i+1] = password[i]
        return true if password_confirmation == possible_confirmation
      end
      # Replace a character by another one
      (0..(n-1)).each do |i|
        possible_confirmation = password.clone
        possible_confirmation[i] = password_confirmation[i]
        return true if password_confirmation == possible_confirmation
      end
    elsif password_confirmation.size == n-1
      # Forget one character
      (0..(n-1)).each do |i|
        possible_confirmation = (i > 0 ? password[0..i-1] : "") + (i < n-1 ? password[(i+1)..(n-1)] : "")
        return true if password_confirmation == possible_confirmation
      end
    elsif password_confirmation.size == n+1
      # Adds one character
      (0..n).each do |i|
        possible_confirmation = (i > 0 ? password[0..i-1] : "") + password_confirmation[i] + (i < n ? password[i..(n-1)] : "")
        return true if password_confirmation == possible_confirmation
      end
    end
    return false
  end
  
  # Helper method to make everybody with some skin leaves this skin
  def remove_skins(user)
    User.where(skin: @user.id).each do |u|
      u.update_attribute(:skin, 0)
    end
  end
  
  # Helper method to fill @allsec and @maxscore
  def fill_sections_max_score
    @allsec = Section.order(:id).where(:fondation => false).to_a
    @maxscore = Array.new
    @allsec.each do |s|
      @maxscore[s.id] = s.max_score
    end
  end
  
  # Helper method to fill informations for a set of users (for ranking page)
  def fill_user_info(users)
    num = users.size
    @x_recent = Array.new(num)
    @x_persection = Array.new(num)
    @x_globalrank = Array.new(num)
    @x_country = Array.new(num)
    @x_rating = Array.new(num)
    @x_linked_name = Array.new(num)
    
    global_user_id_to_local_id = Array.new((User.last.nil? ? 0 : User.last.id) + 1)

    ids = Array.new(users.size)
    local_id = 0
    
    num_user_by_rating = nil
    if !@num_users_in_country_by_rating.nil? && !@country.nil? && @country == 0
      num_users_by_rating = @num_users_in_country_by_rating # Avoid recomputing it
    else
      num_users_by_rating = User.where(:role => :student).where("rating > 0").group(:rating).order("rating DESC").count
    end
    
    rank_by_rating = {}
    
    r = 1
    num_users_by_rating.each do |rating, num|
      rank_by_rating[rating] = r
      r = r + num
    end
    rank_by_rating[0] = r
    
    # Old way of computing the rank, but was not very efficient:
    # globalrank_here = User.select("users.id, (SELECT COUNT(u.id) FROM users AS u WHERE u.rating > users.rating AND u.role = 1) + 1 AS ranking").where(:id => users.map(&:id)).order("rating DESC").to_a.map(&:ranking)

    users.each do |u|
      ids[local_id] = u.id
      global_user_id_to_local_id[u.id] = local_id
      @x_persection[local_id] = Array.new
      @x_recent[local_id] = 0
      @x_rating[local_id] = u.rating
      @x_globalrank[local_id] = rank_by_rating[u.rating]
      @x_country[local_id] = u.country_id
      @x_linked_name[local_id] = u.linked_name
      local_id = local_id + 1
    end

    # Sort users with rank 1 in random order (only if at least 2 people with rank 1)
    if local_id >= 2 && @x_globalrank[1] == 1
      s = 2
      while s < local_id && @x_globalrank[s] == 1
        s = s + 1
      end
      r = Random.new(Date.today.in_time_zone.to_time.to_i)
      alea = Array.new(s)
      (0..(s-1)).each do |i|
        x = r.rand()
        if signed_in? && ids[i] == current_user.id
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
        save_country[i] = @x_country[i]
        save_linked_name[i] = @x_linked_name[i]
      end
      (0..(s-1)).each do |i|
        ids[i] = save_ids[alea[i][1]]
        @x_country[i] = save_country[alea[i][1]]
        @x_linked_name[i] = save_linked_name[alea[i][1]]
        global_user_id_to_local_id[ids[i]] = i
      end
    end

    # NB: Need to deduct days before converting to datetime, otherwise we can have an issue with time change, twice a year
    twoweeksago = (Date.today - 13.days).in_time_zone.to_datetime

    Solvedproblem.where(:user_id => ids).includes(:problem).where("resolution_time >= ?", twoweeksago).find_each do |s|
      @x_recent[global_user_id_to_local_id[s.user_id]] += s.problem.value
    end

    Solvedquestion.where(:user_id => ids).includes(:question).where("resolution_time >= ?", twoweeksago).find_each do |s|
      @x_recent[global_user_id_to_local_id[s.user_id]] += s.question.value
    end

    Pointspersection.where(:user_id => ids).all.each do |p|
      @x_persection[global_user_id_to_local_id[p.user_id]][p.section_id] = p.points
    end
  end  
end
