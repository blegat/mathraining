Recaptcha.configure do |config|
  if Rails.env.production?
    config.site_key   = Rails.application.credentials.dig(:recaptcha_site_key)
    config.secret_key = Rails.application.credentials.dig(:recaptcha_secret_key)
  else
    config.site_key   = Rails.application.credentials.dig(:recaptcha_site_key_localhost)
    config.secret_key = Rails.application.credentials.dig(:recaptcha_secret_key_localhost)
  end
  # config.proxy = 'http://myproxy.com.au:8080'
end
