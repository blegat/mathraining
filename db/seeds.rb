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

if !Rails.env.test?
  Country.create(name: "Belgique", code: "be")
end

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
		for j in 1..3
			chapitre[i][j] = Chapter.new(name: "Chapitre de la section " + i.to_s + ", numéro " + j.to_s, description: "C'est intéressant", level: j, order: 1, online: true)
			chapitre[i][j].section = section[i]
			chapitre[i][j].save
			
			# Exercices
			exercice[i][j] = Array.new
			qcm[i][j] = Array.new
			choice[i][j] = Array.new
			for k in 1..4
				exercice[i][j][k] = Question.new(statement: "Quelle est la valeur de " + k.to_s + "?", decimal: (k % 2 == 1), answer: k, position: k, online: true, explanation: "C'est du bon sens!", level: k, many_answers: false)
				exercice[i][j][k].chapter = chapitre[i][j]
				exercice[i][j][k].save
			end
			
			# Qcms
			for k in 1..3
				qcm[i][j][k] = Question.new(statement: "Quelle est la valeur de " + k.to_s + "?", many_answers: (k % 2 == 1), position: 4+k, online: true, explanation: "C'est du bon sens!", level: k, decimal: false, answer: 0)
				qcm[i][j][k].chapter = chapitre[i][j]
				qcm[i][j][k].save
				choice[i][j][k] = Array.new
				
				for l in 1..3
					choice[i][j][k][l] = Item.new(ans: l.to_s, ok: (k == l))
					choice[i][j][k][l].question = qcm[i][j][k]
					choice[i][j][k][l].save
				end
			end
		end
	end
	
	# Problèmes
	problem = Array.new
	for i in 1..6
		problem[i] = Array.new
		for j in 1..5
			problem[i][j] = Array.new
			for k in 1..4
				problem[i][j][k] = Problem.new(statement: "Trouver la valeur de " + i.to_s + " + " + j.to_s + " + " + k.to_s + ".", online: true, level: j, explanation: "Il s'avère que la réponse est " + (i+j+k).to_s + ".", number: i*1000 + j*100 + k*20, origin: "La nuit des temps.")
				problem[i][j][k].section = section[i]
				problem[i][j][k].save
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
						solved = Solvedquestion.new(guess: 18, correct: false, nb_guess: Random.rand(3)+1)
						solved.question = exercice[j][k][l]
						solved.user = user[i]
						solved.save
					else
						solved = Solvedquestion.new(guess: l, correct: true, nb_guess: Random.rand(3)+1, resolutiontime: DateTime.now)
						solved.question = exercice[j][k][l]
						solved.user = user[i]
						solved.save
						user[i].rating = user[i].rating + 3*l
						user[i].save
					end
				end
			end
		end
		
		for j in 1..6
			for k in 1..5
				for l in 1..4
					r = Random.rand(10)
					if r == 0
						# Soumission correcte
						rr = Random.rand(30)
						sub = Submission.new(content: "C'est facile, il suffit d'effectuer " + j.to_s + " + " + k.to_s + " qui donne " + (j+k).to_s + ", puis on ajoute " + l.to_s + " et cela donne " + (j+k+l).to_s + ".", status: (rr == 0 ? 0 : 2), intest: false, visible: true, score: -1, lastcomment: (rr != 0 ? DateTime.now : DateTime.now + 1/1440.0), star: (rr != 0 and Random.rand(5) == 0))
						sub.problem = problem[j][k][l]
						sub.user = user[i]
						sub.save
						if rr != 0
							# Dans ce cas c'est corrigé (sinon en attente)
							solved = Solvedproblem.new(resolutiontime: DateTime.now, truetime: DateTime.now)
							solved.user = user[i]
							solved.problem = problem[j][k][l]
							solved.submission = sub
							solved.save
							
							corrector = (Random.rand(2) == 0 ? admin : root)
							
							correction = Correction.new(content: "Parfait!")
							correction.user = corrector
							correction.submission = sub
							correction.save
							
							following = Following.new(read: true)
							following.user = corrector
							following.submission = sub
							following.save
							
							user[i].rating = user[i].rating + 15*k
							user[i].save
						end
					elsif r == 1
						# Soumission fausse
						rr = Random.rand(30)
						sub = Submission.new(content: "C'est facile, il suffit d'effectuer " + j.to_s + " + " + k.to_s + " qui donne " + (j+k+1).to_s + ", puis on ajoute " + l.to_s + " et cela donne " + (j+k+l+1).to_s + ".", status: (rr == 0 ? 0 : 1), intest: false, visible: true, score: -1, lastcomment: (rr != 0 ? DateTime.now : DateTime.now + 1/1440.0), star: false)
						sub.problem = problem[j][k][l]
						sub.user = user[i]
						sub.save
						if rr != 0
							# Dans ce cas c'est corrigé (sinon en attente)
							
							corrector = (Random.rand(2) == 0 ? admin : root)
							
							correction = Correction.new(content: "Il y a une petite erreur quelquepart...")
							correction.user = corrector
							correction.submission = sub
							correction.save
							
							following = Following.new(read: true)
							following.user = corrector
							following.submission = sub
							following.save
						end
					end
				end
			end
		end
	end
end
