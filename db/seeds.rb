# encoding: utf-8

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


# Sections
section = Array.new

section[1] = Section.create(name: "Combinatoire", description: "", fondation: false)
section[2] = Section.create(name: "Géométrie", description: "", fondation: false)
section[3] = Section.create(name: "Théorie des nombres", description: "", fondation: false)
section[4] = Section.create(name: "Algèbre", description: "", fondation: false)
section[5] = Section.create(name: "Équations fonctionnelles", description: "", fondation: false)
section[6] = Section.create(name: "Inégalités", description: "", fondation: false)
section[7] = Section.create(name: "Fondements", description: "", fondation: true)

if !Rails.env.production?

	# Actualités
	Actuality.create(title: "Bienvenue sur Mathraining!", content: "Vous êtes les bienvenus !")

	# Chapitres
	chapitre = Array.new
	exercice = Array.new
	qcm = Array.new
	choice = Array.new
	for i in 1..7
		chapitre[i] = Array.new
		exercice[i] = Array.new
		qcm[i] = Array.new
		choice[i] = Array.new
		for j in 1..4
			chapitre[i][j] = Chapter.new(name: "Chapitre de la section " + i.to_s + ", numéro " + j.to_s, description: "C'est intéressant", level: j, online: true)
			chapitre[i][j].section = section[i]
			chapitre[i][j].save
			
			# Exercices
			exercice[i][j] = Array.new
			qcm[i][j] = Array.new
			choice[i][j] = Array.new
			for k in 1..4
				exercice[i][j][k] = Exercise.new(statement: "Quelle est la valeur de " + k.to_s + "?", decimal: (k % 2 == 1), answer: k, position: k, online: true, explanation: "C'est du bon sens!", level: k)
				exercice[i][j][k].chapter = chapitre[i][j]
				exercice[i][j][k].save
			end
			
			# Qcms
			for k in 1..3
				qcm[i][j][k] = Qcm.new(statement: "Quelle est la valeur de " + k.to_s + "?", many_answers: (k % 2 == 1), position: 4+k, online: true, explanation: "C'est du bon sens!", level: k)
				qcm[i][j][k].chapter = chapitre[i][j]
				qcm[i][j][k].save
				choice[i][j][k] = Array.new
				
				for l in 1..3
					choice[i][j][k][l] = Choice.new(ans: l.to_s, ok: (k == l))
					choice[i][j][k][l].qcm = qcm[i][j][k]
					choice[i][j][k][l].save
				end
			end
		end
	end
	
	# Root
	root = User.create(first_name: "Root", last_name: "Root", email: "root@root.com", password: "foobar", password_confirmation: "foobar", root: true, admin: true, year: 1990, country: "Belgique")
	
	# Admin
	admin = User.create(first_name: "Admin", last_name: "Admin", email: "admin@admin.com", password: "foobar", password_confirmation: "foobar", root: false, admin: true, year: 1990, country: "Belgique")
	
	# User
	user = Array.new
	for i in 1..10
		user[i] = User.new(first_name: "User", last_name: "User " + i.to_s, email: "user@user" + i.to_s + ".com", password: "foobar", password_confirmation: "foobar", root: false, admin: false, year: 2000, country: "Belgique")
		if i % 2 == 1
			user[i].wepion = true
			user[i].save
		end
		
		for j in 1..7
			for k in 1..4
				for l in 1..4
					r = Random.rand(2)
					if r == 0
						solved = Solvedexercise.new(guess: 18, correct: false, nb_guess: Random.rand(3)+1)
						solved.exercise = exercice[j][k][l]
						solved.user = user[i]
						solved.save
					else
						solved = Solvedexercise.new(guess: l, correct: true, nb_guess: Random.rand(3)+1, resolutiontime: DateTime.now)
						solved.exercise = exercice[j][k][l]
						solved.user = user[i]
						solved.save
						user[i].rating = user[i].rating + 3*l
						user[i].save
					end
					
				end
			end
		end
	end
end
