source 'https://rubygems.org'

ruby '3.2.8'                           # Ruby

gem 'rails', '8.1.0'                   # Ruby on Rails

gem 'bootstrap', '5.3.8'               # Responsive design

gem 'bcrypt', '3.1.22'                 # Password encryption

gem 'will_paginate', '3.3.0'           # Pages
gem 'will_paginate-bootstrap-style'    # Bootstrap style for pages

gem 'rails-i18n'                       # Locales (internationalization)

gem 'recaptcha', '~> 5.15',            # Captcha
  :require => 'recaptcha/rails'

gem 'whenever', :require => false      # Plan cron jobs

gem 'resque', '~> 2.5'                 # Emails
gem 'resque_mailer'                    # Emails

group :development do
  gem 'annotaterb'                     # Annotate pages automatically
end

# With bootstrap 5.3.0 we were using sassc and sassc-rails instead of the
# following two gems, but on Ubuntu 26 they were creating some issues
gem 'sass-embedded'                    # CSS preprocessor
gem 'dartsass-sprockets'               # CSS preprocessor

gem 'jquery-rails'                     # Jquery

gem 'select2-rails'                    # Smart select (to select a user)

group :test do
  gem 'rspec-rails', '6.1.5'           # Tests
  gem 'capybara', '3.40.0'             # Tests  
  gem 'capybara-email'                 # Tests (email)
  gem 'puma'                           # Tests (mainly for javascript)
  gem 'factory_bot_rails', '6.4.4'     # Tests (factory bot)
  gem 'database_cleaner-active_record', '>= 2.2.0' # Tests (clean database)
  gem 'capybara-select-2'              # Tests (select2)
  gem 'capybara-screenshot'            # Tests (screenshots to debug)
  gem 'selenium-webdriver'             # Tests (mainly for javascript)
  gem 'rails-controller-testing'       # Tests (template rendering)
  
  gem 'simplecov', :require => false   # Code coverage
  gem 'codecov', :require => false     # Code coverage
end

gem 'pg', '~> 1.1'                     # PostgreSQL
# http://stackoverflow.com/questions/9392939/pg-gem-fails-to-install
# Centos 5 has a too old version of pg

gem 'bootstrap3-datetimepicker-rails', # Pick dates (for constests)
  '~> 4.14.30'

gem 'rack-canonical-host'              # Redirect to www (?)

group :production do
  gem 'passenger', '6.0.27'            # Force 6.0.27 that is set up with Apache on the server
end

gem 'lograge'                          # Better logs

gem 'groupdate', ">= 6.5.0"            # SQL requests grouped by dates

gem 'active_storage_validations'       # Validate attachments

gem "importmap-rails", "~> 1.2"        # For javascript
