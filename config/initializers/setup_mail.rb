# Settings to send with gmail
#ActionMailer::Base.smtp_settings = {
#  :address              => "smtp.gmail.com",
#  :port                 => 587,
#  :domain               => "gmail.com",
#  :user_name            => Rails.application.credentials.dig(:email_user_name), # without @gmail.com
#  :password             => Rails.application.credentials.dig(:email_mathraining_key),
#  :authentication       => "plain",
#  :enable_starttls_auto => true
#}

# Settings to send with noreply@mathraining.be
ActionMailer::Base.smtp_settings = {
  :address              => "pro3.mail.ovh.net",
  :port                 => 587,
  :domain               => "mathraining.be",
  :user_name            => Rails.application.credentials.dig(:email_user_name),
  :password             => Rails.application.credentials.dig(:email_password),
  :authentication       => "plain",
  :enable_starttls_auto => true
}
