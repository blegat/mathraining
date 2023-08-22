# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# Localization
Rails.application.config.i18n.available_locales = :fr
