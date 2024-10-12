source 'https://rubygems.org'

ruby '3.0.0'                           # Ruby

gem 'rails', '7.0.8.4'                 # Ruby on Rails

gem 'bootstrap', '5.3'                 # Responsive design

gem 'bcrypt', '3.1.16'                 # Password encryption

gem 'will_paginate', '3.3.0'           # Pages
gem 'will_paginate-bootstrap-style'    # Bootstrap style for pages

gem 'rails-i18n', '~> 7.0'             # Locales (internationalization)

gem 'recaptcha', '~> 5.15',            # Captcha
  :require => 'recaptcha/rails'

gem 'whenever', :require => false      # Plan cron jobs

# gem 'eventmachine', '1.2.3'
# gem 'thin'

gem 'resque', '~> 2.5'                 # Emails
gem 'resque_mailer'                    # Emails
# gem 'resque_action_mailer_backend'

# group :development, :test do
  # gem 'rspec-rails', '~> 5.0'
  # gem 'random_record'
  # gem 'bullet'
# end

group :development do
  gem 'annotate', '~> 3.2'             # Annotate pages automatically
  # gem 'web-console', '~> 2.0'
end

# gem 'coffee-rails', '~> 5.0.0'
# gem 'uglifier', '>= 1.2.3'

gem 'sassc'                            # CSS preprocessor
gem 'sassc-rails'                      # CSS preprocessor

gem 'jquery-rails'                     # Jquery

gem 'select2-rails'                    # Smart select (to select a user)

group :test do
  gem 'rspec-rails', '~> 5.0'          # Tests
  gem 'capybara', '3.39.2'             # Tests  
  gem 'capybara-email'                 # Tests (email)
  gem 'puma'                           # Tests (mainly for javascript)
  gem 'factory_girl_rails', '4.1.0'    # Tests (factory girl)
  gem 'database_cleaner-active_record' # Tests (clean database)
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

# gem 'therubyracer'
# gem 'less-rails'

# gem 'glyphicons-rails'
# gem 'momentjs-rails', '>= 2.9.0'
gem 'bootstrap3-datetimepicker-rails', # Pick dates (for constests)
  '~> 4.14.30'

gem 'rack-canonical-host'              # Redirect to www (?)

gem 'lograge'                          # Better logs

gem 'groupdate'                        # SQL requests grouped by dates

gem 'active_storage_validations'       # Validate attachments
# gem 'mini_magick'
# gem 'image_processing', '>= 1.2'

gem "importmap-rails", "~> 1.2"        # For javascript
