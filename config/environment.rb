# Load the Rails application.
require_relative 'application'

# Load the app's custom environment variables here,
# so that they are loaded before environments/*.rb
#app_environment_variables = File.join(Rails.root, 'config', 'app_environment_variables.rb')
#load(app_environment_variables) if File.exists?(app_environment_variables)

# Initialize the Rails application.
Rails.application.initialize!

# Localization
Rails.application.config.i18n.available_locales = :fr
