Recaptcha.configure do |config|
  config.site_key  = '6LctwucSAAAAAPiI_Zq5pA4nwPfK928l6-5JjTLU'
  config.secret_key = ENV['CAPTCHA_PRIVATE_KEY']
  # config.proxy = 'http://myproxy.com.au:8080'
end
