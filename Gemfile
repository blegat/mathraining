source 'https://rubygems.org'

ruby '3.0.0'

gem 'rails', '= 7.0'

#gem 'bootstrap-sass', '~> 3.4.1'
gem 'bootstrap', '5.3'
gem 'bcrypt', '3.1.16'
gem 'will_paginate', '3.3.0'
gem 'will_paginate-bootstrap-style'
gem 'rails-i18n', '~> 7.0'
gem 'recaptcha', '~> 5.15', :require => 'recaptcha/rails'
gem 'thin'

# Doing tasks every monday...
gem 'whenever', :require => false

# Otherwise it doesn't work
gem 'eventmachine', '1.2.3'

gem 'resque', '~> 2.5'
gem 'resque_mailer'
gem 'resque_action_mailer_backend'

group :development, :test do
  gem 'sqlite3', '~> 1.4'
  gem 'rspec-rails', '~> 5.0'
  gem 'random_record'
  gem 'bullet'
end

group :development do
  gem 'annotate', '~> 3.2'
  gem 'web-console', '~> 2.0'
end

# Gems used only for assets and not required in production environments by default.
#group :assets do ## Removed in Rails 4 and was making rake assets:precompile fail!
#gem 'sass-rails',   '~> 5.0.1'
gem 'coffee-rails', '~> 5.0.0'
gem 'uglifier', '>= 1.2.3'
#end

gem 'sassc', '= 2.2.0' # Otherwise it tries to install 2.4.0 and it fails for some reason
gem 'sassc-rails'

gem 'jquery-rails'

gem 'select2-rails'

gem 'activerecord-session_store', '= 2.0.0'

group :test do
  gem 'capybara', '3.39.2'
  gem 'capybara-email'
  gem 'puma'
  gem 'factory_girl_rails', '4.1.0'
  gem 'database_cleaner-active_record'
  #gem 'capybara-webkit'
  gem 'capybara-select-2'
  gem 'capybara-screenshot'
  gem 'selenium-webdriver'
  gem 'rails-controller-testing'
  #gem 'poltergeist'
  # Code coverage
  gem 'simplecov', :require => false
  gem 'codecov', :require => false
end

group :production do
  gem 'pg', '~> 1.1'
  # http://stackoverflow.com/questions/9392939/pg-gem-fails-to-install
  # Centos 5 has a too old version of pg
end

gem 'therubyracer'
gem 'less-rails'

# date and time for contests
gem 'glyphicons-rails'
gem 'momentjs-rails', '>= 2.9.0'
gem 'bootstrap3-datetimepicker-rails', '~> 4.14.30'
gem 'rack-canonical-host'
gem 'lograge'
gem 'groupdate'

gem 'active_storage_validations'
gem 'mini_magick'
gem 'image_processing', '>= 1.2'

gem "importmap-rails", "~> 1.2"
