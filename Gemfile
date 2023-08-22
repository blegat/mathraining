source 'https://rubygems.org'

ruby "2.7.8"

gem 'rails', '= 6.0'
# The following lines are probably not mandatory but without them the 'Resolving dependencies' of 'bundle update rails' was taking ages
gem 'actioncable', '= 6.0'
gem 'actionmailer', '= 6.0'
gem 'actionpack', '= 6.0'
gem 'actionview', '= 6.0'
gem 'activejob', '= 6.0'
gem 'activemodel', '= 6.0'
gem 'activerecord', '= 6.0'
gem 'activestorage', '= 6.0'
gem 'activesupport', '= 6.0'
gem 'railties', '= 6.0'

#gem 'activeresource', '~> 4.1.0'
# gem 'protected_attributes'
gem "bootstrap-sass", "~> 3.4.1"
gem 'bcrypt', '3.1.16'
gem 'faker', '1.0.1'
gem 'will_paginate', '3.1.7'
gem 'bootstrap-will_paginate', '0.0.10'
gem 'rails-i18n', '~> 7.0'
#gem 'mathjax-rails', "~> 0.0.4"
#gem "paperclip", "~> 5.2.0"
gem "recaptcha", "~> 4.1.0", :require => "recaptcha/rails"
gem 'thin'
#gem "nokogiri", "~> 1.11.4"

# Doing tasks every monday...
gem 'whenever', :require => false

# Otherwise it doesn't work
gem 'eventmachine', "1.2.3"

gem "resque", "~> 1.27.3"
gem 'resque_mailer'
#gem 'resque-web', require: 'resque_web'
gem 'resque_action_mailer_backend'

# Markdown
#gem 'redcarpet' # server-side
#gem 'kramdown' # server-side
#gem 'pagedown-rails', '~> 1.1.2' # client-side

group :development, :test do
  gem "sqlite3", "~> 1.4"
  gem 'rspec-rails', '3.5'
  gem 'random_record'

  gem 'bullet'
end

gem "annotate", "~> 3.1.1", group: :development
gem 'web-console', '~> 2.0', group: :development

# Gems used only for assets and not required
# in production environments by default.
#group :assets do ## Removed in Rails 4 and was making rake assets:precompile fail!
  gem 'sass-rails',   '~> 5.0.1'
  gem 'coffee-rails', '~> 5.0.0'
  gem 'uglifier', '>= 1.2.3'
#end

gem 'sassc', '= 2.1.0' # Otherwise it tries to install 2.4.0 and it fails for some reason

gem 'jquery-rails'

gem 'select2-rails'

gem 'activerecord-session_store', '= 1.1.3'

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
  gem 'pg', '~> 0.20.0'
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
