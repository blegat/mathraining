include ApplicationHelper

def sign_in(user)
  visit root_path
  click_link "Connexion"
  fill_in "header_connect_email", with: user.email
  fill_in "header_connect_password", with: user.password
  click_button "header_connect_button"
end

def sign_out
  visit root_path
  click_link "Déconnexion"
end

def error_access_refused
  return "Désolé... Cette page n'existe pas ou vous n'y avez pas accès."
end

def error_must_be_connected
  return "Vous devez être connecté pour accéder à cette page."
end

def create_discussion_between(user1, user2, content1, content2)
  d = Discussion.new
  d.last_message_time = DateTime.now
  d.save
  link = Link.new
  link.user_id = user1.id
  link.discussion_id = d.id
  link.nonread = 0
  link.save
  link2 = Link.new
  link2.user_id = user2.id
  link2.discussion_id = d.id
  link2.nonread = 0
  link2.save
  m = Tchatmessage.new
  m.user_id = user1.id
  m.content = content1
  m.discussion_id = d.id
  m.save
  m2 = Tchatmessage.new
  m2.user_id = user2.id
  m2.content = content2
  m2.discussion_id = d.id
  m2.save
  return d
end

def options_for_user_titles(country_id, for_root)
  num_before = 0
  if country_id == 0
    num_tot = User.where("admin = ? AND active = ? AND rating > 0", false, true).count
  else
    num_tot = User.where("admin = ? AND active = ? AND rating > 0 AND country_id = ?", false, true, country_id).count
  end
  options = ["Tous les titres (#{num_tot})"]
  Color.order("pt DESC").each do |c|
    if country_id == 0
      num = User.where("admin = ? AND active = ? AND rating > 0 AND rating >= ?", false, true, c.pt).count
    else
      num = User.where("admin = ? AND active = ? AND rating > 0 AND rating >= ? AND country_id = ?", false, true, c.pt, country_id).count
    end
    options.push("#{pluriel(c.name)} (#{num-num_before})")
    num_before = num
  end
  
  if for_root
    if country_id == 0
      num_zero = User.where(:admin => false, :active => true, :rating => 0).count
      num_admin = User.where(:admin => true, :active => true).count
    else
      num_zero = User.where(:admin => false, :active => true, :country_id => country_id, :rating => 0).count
      num_admin = User.where(:admin => true, :active => true, :country_id => country_id).count
    end
    options.push("Non classés (#{num_zero})")
    options.push("Administrateurs (#{num_admin})")
  end
  
  return options
end

RSpec::Matchers.define :have_user_line do |line_id, rank_str, user|
  match do |page|
    expect(page).to have_selector("#rank_#{line_id}", text: rank_str, exact_text: true)
    expect(page).to have_selector("#name_#{line_id}", text: user.name)
    expect(page).to have_css("img[id=flag_#{line_id}_#{user.country.id}]")
    expect(page).to have_selector("#score_#{line_id}", text: user.rating.to_s, exact_text: true)
    
    Section.where(:fondation => false).each do |s|
      if s.max_score > 0
        pps = Pointspersection.where(:section => s, :user => user).first
        if !pps.nil?
          expect(page).to have_selector("#pct_section_#{line_id}_#{s.id}", text: (pps.points == 0 ? "-" : (100*pps.points/s.max_score).to_s + "%"), exact_text: true)
        end
      end
    end
    
    recent_points = 0
    twoweeksago = Date.today - 14.days
    user.solvedproblems.includes(:problem).where("resolution_time > ?", twoweeksago).each do |s|
      recent_points += s.problem.value
    end
    user.solvedquestions.includes(:question).where("resolution_time > ?", twoweeksago).each do |s|
      recent_points += s.question.value
    end
    expect(page).to have_selector("#recent_#{line_id}", text: (recent_points == 0 ? "" : "+ " + recent_points.to_s), exact_text: true)
  end
end

def wait_for_ajax
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until finished_all_ajax_requests?
  end
end

def finished_all_ajax_requests?
  page.evaluate_script('jQuery.active').zero?
end

# The following method has some issues: instead of using it we prefer to remove confirmations when Rails.env.test? = true
def accept_browser_dialog
  wait = Selenium::WebDriver::Wait.new(:timeout => 10)
  wait.until {
    begin
      page.driver.browser.switch_to.alert
      true
    rescue Selenium::WebDriver::Error::NoAlertPresentError
      false
    end
  }
  page.driver.browser.switch_to.alert.accept
  sleep(1) # This is the issue: it looks like we need to wait some time (how much?) manually
end

def take_screenshot
  Capybara::Screenshot.screenshot_and_open_image
end

RSpec::Matchers.define :have_error_message do |message|
  match do |page|
    expect(page).to have_selector("div.alert.alert-danger", text: message)
  end
end

RSpec::Matchers.define :have_info_message do |message|
  match do |page|
    expect(page).to have_selector("div.alert.alert-info", text: message)
  end
end

RSpec::Matchers.define :have_success_message do |message|
  match do |page|
    expect(page).to have_selector("div.alert.alert-success", text: message)
  end
end
