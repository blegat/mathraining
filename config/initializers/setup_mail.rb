ActionMailer::Base.smtp_settings = {
  :address				=> "smtp.gmail.com",
  :port					=> 587,
  :domain				=> "mathraining",
  :user_name			=> ENV['EMAIL_ADDRESS'],
  :password				=> ENV['EMAIL_PASSWORD'],
  :authentication		=> "plain",
  :enable_starttls_auto	=> true
}
