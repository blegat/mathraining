Recaptcha.configure do |config|
  config.public_key  = '6Lc4wucSAAAAABz6NLwneQU8lb2ddnEIblWELqcx'
  config.private_key = ENV['PRIVATE_KEY']
  # config.proxy = 'http://myproxy.com.au:8080'
end
