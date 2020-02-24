source 'https://rubygems.org'

gem 'rails', '5.0.2'
#gem 'activeresource', '~> 4.1.0'
# gem 'protected_attributes'
gem "bootstrap-sass", "~> 3.2.0"
gem 'bcrypt-ruby', '3.1.2'
gem 'faker', '1.0.1'
gem 'will_paginate', '3.1.6'
gem 'bootstrap-will_paginate', '0.0.10'
gem 'rails-i18n'
#gem 'mathjax-rails', "~> 0.0.4"
gem "paperclip", "~> 5.1.0"
gem "recaptcha", "~> 4.1.0", :require => "recaptcha/rails"
gem 'thin'
gem "nokogiri", "~> 1.10.8"

# Doing tasks every monday...
gem 'whenever', :require => false

# Otherwise it doesn't work
gem 'eventmachine', "1.2.3"

gem "resque", "~> 1.27.3"
gem 'resque_mailer'
gem 'resque-web', require: 'resque_web'
gem 'resque_action_mailer_backend'

# Markdown
#gem 'redcarpet' # server-side
#gem 'kramdown' # server-side
#gem 'pagedown-rails', '~> 1.1.2' # client-side

group :development, :test do
  gem "sqlite3", "~> 1.3.6"
  gem 'rspec-rails', '3.5'
  gem 'random_record'

  gem 'bullet'
end

gem "annotate", "~> 2.5.0", group: :development
gem 'web-console', '~> 2.0', group: :development

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 5.0.1'
  gem 'coffee-rails', '~> 4.2.1'
  gem 'uglifier', '>= 1.2.3'
end

gem 'jquery-rails'

gem 'select2-rails'

gem 'activerecord-session_store'

group :test do
  gem 'capybara', '2.12.1'
  gem 'factory_girl_rails', '4.1.0'
  gem 'database_cleaner', '1.5.3'
  gem 'capybara-webkit'
  gem 'selenium-webdriver', '2.53.4'
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
gem "lograge"