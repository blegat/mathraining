namespace :db do
  desc "Drop, create, migrate and repopulate db"
  task rebuild: [:environment,
    :drop, :create, :migrate, :seed, :populate]
end
