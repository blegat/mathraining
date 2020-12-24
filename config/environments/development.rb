Mathraining::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb
  
  Paperclip.options[:command_path] = "/usr/local/bin/"

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  # config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  #config.active_record.mass_assignment_sanitizer = :strict
  #removed when upgrading

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false
  
  config.eager_load = false

  # Expands the lines which load the assets
  # config.assets.debug = true

  # Enable SQL debugging
  enable_sql_debugging = false # Set this to false if you don't want it
  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true

    Bullet.add_whitelist :type => :unused_eager_loading, :class_name => "Subject", :association => :chapter
    Bullet.add_whitelist :type => :unused_eager_loading, :class_name => "Subject", :association => :section
    Bullet.add_whitelist :type => :unused_eager_loading, :class_name => "Subject", :association => :exercise
  end if enable_sql_debugging
  
  # Personalized logs 
  config.log_tags = [ lambda { |req| Time.now}, :remote_ip ] # Include IP address in the logs
  config.log_level = :debug # Set to :debug for more information (not sure it works with lograge)
  
  # lograge is a gem for 'better' logs
  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    { params: event.payload[:params].except('controller', 'action', 'format', 'utf8') } # Include the form parameters
  end
  
  config.lograge.custom_payload do |controller|
    { current_user: controller.current_user.try(:id) } # Include the current_user.id
  end

end
