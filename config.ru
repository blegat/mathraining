# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)

# The variable ENV['ADDRESS_WITH_WWW'] is only set in app_environement_variables.rb on the server (to avoid redirection when developing)
use Rack::CanonicalHost, ENV['ADDRESS_WITH_WWW'] if ENV['ADDRESS_WITH_WWW']

run Mathraining::Application
