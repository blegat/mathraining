Recaptcha.configure do |config|
  config.site_key  = '6Lc4wucSAAAAABz6NLwneQU8lb2ddnEIblWELqcx'
  config.secret_key = ENV['PRIVATE_KEY']
  # config.proxy = 'http://myproxy.com.au:8080'
end
