source 'https://rubygems.org'

gem 'rails', '4.0.0'
gem 'activeresource', '~> 4.0.0'
gem 'protected_attributes'
gem "bootstrap-sass", "~> 3.2.0"
gem 'bcrypt-ruby', '3.0.1'
gem 'faker', '1.0.1'
gem 'will_paginate', '3.0.4'
gem 'bootstrap-will_paginate', '0.0.10'
gem 'rails-i18n'
#gem 'mathjax-rails', "~> 0.0.4"
gem "paperclip", :git => "git://github.com/thoughtbot/paperclip.git"
gem "recaptcha", :require => "recaptcha/rails"
gem 'thin'
gem "nokogiri", "~> 1.6.0"

gem "resque", "~> 2.0.0.pre.1", github: "resque/resque"
gem 'resque_mailer'
gem 'resque-web', require: 'resque_web'

# Markdown
gem 'redcarpet' # server-side
gem 'kramdown' # server-side
gem 'pagedown-rails', '~> 1.1.2' # client-side

group :development, :test do
  gem 'sqlite3'
  gem 'rspec-rails', '2.11.0'
  gem 'random_record'
end

gem "annotate", "~> 2.5.0", group: :development

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 4.0.0'
  gem 'coffee-rails', '~> 4.0.0'
  gem 'uglifier', '>= 1.2.3'
end

gem 'jquery-rails'

group :test do
  gem 'capybara', '1.1.2'
  gem 'factory_girl_rails', '4.1.0'
  gem 'database_cleaner', '0.7.0'
end

group :production do
  gem 'pg', '~> 0.14.1'
# http://stackoverflow.com/questions/9392939/pg-gem-fails-to-install
# Centos 5 has a too old version of pg
end

