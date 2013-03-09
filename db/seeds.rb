# encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Section.create(name: "Fondements", description: "", image: "fondations.jpg", fondations: true)
Section.create(name: "Combinatoire", description: "", image: "combinatorics.jpg", fondations: false)
Section.create(name: "Géométrie", description: "", image: "geometry.jpg", fondations: false)
Section.create(name: "Théorie des nombres", description: "", image: "numbertheory.jpg", fondations: false)
Section.create(name: "Algèbre", description: "", image: "algebra.jpg", fondations: false)
