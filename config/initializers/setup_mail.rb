ActionMailer::Base.smtp_settings = {
  :address				=> "smtp.gmail.com",
  :port					=> 587,
  :domain				=> "mathraining",
  :user_name			=> Rails.application.credentials.dig(:email_user_name),
  :password				=> Rails.application.credentials.dig(:email_mathraining_key), # email_password cannot be used because of 2-step verification
  :authentication		=> "plain",
  :enable_starttls_auto	=> true
}
