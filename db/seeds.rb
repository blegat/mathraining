# encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Section.create(name: "Combinatoire", description: "", image: "combinatorics.jpg")
Section.create(name: "Géométrie", description: "", image: "geometry.jpg")
Section.create(name: "Théorie des nombres", description: "", image: "numbertheory.jpg")
Section.create(name: "Algèbre", description: "", image: "algebra.jpg")
