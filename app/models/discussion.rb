#encoding: utf-8

# == Schema Information
#
# Table name: discussions
#
#  id                :integer          not null, primary key
#  last_message_time :datetime
#
class Discussion < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_many :links, dependent: :destroy
  has_many :users, through: :links
  has_many :tchatmessages, dependent: :destroy

  # OTHER METHODS
  
  # Get several messages (used in controller and in view)
  def get_some_messages(page, per_page)
    return self.tchatmessages.includes(:user).order("created_at DESC").paginate(page: page, per_page: per_page).to_a
  end
  
  # Get the discussion between two users (or nil if it does not exist)
  def self.get_discussion_between(x, y)
    return Discussion.joins("INNER JOIN links a ON discussions.id = a.discussion_id").joins("INNER JOIN links b ON discussions.id = b.discussion_id").where("a.user_id" => x, "b.user_id" => y).first
  end
  
  # Send a message from user x to user y (used only for some specific cases: cannot have attachments here)
  def self.send_message_from_to(x, y, content, obj = nil)
    # Get existing discussion or create new one
    new_discussion = false
    discussion = self.get_discussion_between(x, y)
    if discussion.nil?
      discussion = Discussion.create(:last_message_time => DateTime.now)
      new_discussion = true
    end
    
    # Create message
    tchatmessage = Tchatmessage.new(:user => x, :discussion => discussion, :content => content)
    if !tchatmessage.save
      if new_discussion
        discussion.destroy
      end
      return tchatmessage
    end
      
    # Send email if needed
    unless @limited_emails
      UserMailer.new_followed_tchatmessage(y, x, discussion.id).deliver if y.follow_message
    end
    
    # Update last message time
    discussion.update_attribute(:last_message_time, tchatmessage.created_at)
    
    # Create or update links (with new number of unread messages)
    if new_discussion
      Link.create(:user => x, :discussion => discussion, :nonread => 0)
      Link.create(:user => y, :discussion => discussion, :nonread => 1)
    else
      discussion.links.each do |l|
        if l.user_id == x.id
          l.update_attribute(:nonread, (l.nonread == 0 ? 0 : l.nonread + 1))
        elsif l.user_id == y.id
          l.update_attribute(:nonread, l.nonread + 1)
        end
      end
    end
    
    return tchatmessage
  end
  
  # Answer to discussions related to the puzzles (done every 14 or 23 minutes (see schedule.rb))
  def self.answer_puzzle_questions(t)
    email = (t == 1 ? "j@h.fr" : "cj@dlvp.be")
    threshold = (t == 1 ? 0.4 : 0.2)
  
    r = Random.new(DateTime.now.to_i + t)
    return if r.rand() >= threshold && !Rails.env.test?
    
    # Get user
    user = User.where(:email => email).first
    return if user.nil?
    
    # Loop over all unread discussions
    update_connexion_date = true
    user.links.includes(:discussion).where("nonread > 0").each do |link|
      num_unread_messages = link.nonread
      discussion = link.discussion
      other_link = discussion.links.where("user_id != ?", user.id).first
      next if other_link.nil?
      other_user = other_link.user
      next if other_user.nil?
      
      # Only answer if puzzles started or other_user is a root (for testing)
      next unless Puzzle.started_or_root(other_user)
      
      # Check if the correct question has been asked at some point
      correct_question = false
      last_date = DateTime.now
      discussion.tchatmessages.order(:created_at).last(num_unread_messages).each do |m|
        last_date = m.created_at
        if m.content.strip.gsub("?", " ?").squeeze(' ').upcase.include?("Quel est le code de la dernière énigme ?".upcase)
          correct_question = true
        end
      end

      # Don't answer too fast, and avoid error with two tchatmessages having the same created_at
      next if last_date > DateTime.now - 1.minute
      
      # Compute correct answer
      if correct_question
        content = (t == 1 ? "Le code est simplement $$2 \\times p\\!\\left(2^2 \\times p\\!\\left(2^3 \\times p\\!\\left(2^3\\right) \\times p\\!\\left(2^2 \\times p(p(p(2)))\\right)\\right)\\right)$$ où $p(i)$ désigne le $i^\\text{ème}$ nombre premier." : "Je ne connais pas le code, mais je sais que mon collègue manipule de si grands nombres qu'il utilise également les lettres de l'alphabet pour les écrire. Il prétend d'ailleurs que la réponse à la grande question sur la vie, l'Univers et le reste est $16$ :-O")
      else
        content = (t == 1 ? "Je ne comprends pas ce que vous dites." : "J'ai du mal à vous comprendre.")
      end
      
      # Read the messages (because send_message_from will add 1 to nonread if it's not 0 already)
      link.update_attribute(:nonread, 0)
      
      # Send message
      self.send_message_from_to(user, other_user, content)
      
      # Update connexion date so that user still appears in the list of active users
      if update_connexion_date
        user.update_attribute(:last_connexion_date, Date.today)
        update_connexion_date = false
      end
    end
  end
end
