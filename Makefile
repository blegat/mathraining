run:
	rake db:drop
	rake db:create
	rake db:migrate
	rake db:seed
	rake db:populate
