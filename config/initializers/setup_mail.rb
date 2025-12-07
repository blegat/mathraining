ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port	                => 587,
  :domain               => "gmail.com",
  :user_name            => Rails.application.credentials.dig(:email_user_name),
  :password             => Rails.application.credentials.dig(:email_mathraining_key),
  :authentication       => "plain",
  :enable_starttls_auto => true
}

# Settings to send with no-reply@mathraining.be
#ActionMailer::Base.smtp_settings = {
#  :address              => "ssl0.ovh.net",
#  :port                 => 587,
#  :domain               => "mathraining.be",
#  :user_name            => Rails.application.credentials.dig(:email_user_name), # no-reply@mathraining.be
#  :password             => Rails.application.credentials.dig(:email_password),
#  :authentication       => "plain",
#  :enable_starttls_auto => true
#}
