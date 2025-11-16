ActionMailer::Base.smtp_settings = {
  :address              => "ssl0.ovh.net",
  :port	                => 995,
  :domain               => "mathraining.be",
  :user_name            => Rails.application.credentials.dig(:email_user_name),
  :password             => Rails.application.credentials.dig(:email_password),
  :authentication       => "plain",
  :enable_starttls_auto => true,
  :ssl                  => true,
  :tls                  => true
}
