Mathraining
============
[![Build Status](https://github.com/blegat/mathraining/actions/workflows/ci.yml/badge.svg)](https://github.com/blegat/mathraining/actions/workflows/ci.yml)
[![codecov](https://codecov.io/github/blegat/mathraining/branch/master/graph/badge.svg?token=npRf7TYZ7e)](https://codecov.io/github/blegat/mathraining)

Description
-----------
Code source de [Mathraining](http://www.mathraining.be),
le site interactif d'initiation à la résolution de problèmes mathématiques avancés.

Vous êtes libres et encouragés à participer à son développement en soumettant
des bugs ou suggestions d'amélioration.

How to test the website locally
-------------------------------
First you need to clone the github repository (or a fork of it) on your computer:
```sh
$ git clone https://github.com/blegat/mathraining
```
In the created folder 'mathraining', you should install the needed 'gems':
```sh
$ bundle config set --local without 'production'
$ bundle install
```
Then it is time to create the database:
```sh
$ rake db:create    # Create the database
$ rake db:migrate   # Migrate the database (see db/migrate/)
$ rake db:seed      # Seed the database (see db/seeds.rb)
$ rake db:populate  # Populate the database (see lib/tasks/sample_data.rake)
```
To test the website locally, you can simply do:
```sh
$ rails s  # And then visit localhost:3000 in your browser
```
To run tests, do:
```sh
$ rake db:test:prepare  # Needs to be done when the database structure changes
$ rspec .               # The '.' can be replaced by the path to one file in spec/
```
