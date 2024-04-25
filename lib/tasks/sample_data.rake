#encoding: utf-8
namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    create_actualities
    create_chapters
    create_questions
    create_problems
    update_sections
    create_users
    create_solvedquestions
    update_users_ratings # To know if the user can create submissions
    create_submissions
    update_users_ratings
    create_subjects
    update_statistics
    create_visitor_statistics
  end
end

# Create actualities
def create_actualities
  Actuality.create!(title: "Bienvenue sur Mathraining !", content: "Vous êtes les bienvenus !", created_at: DateTime.now - 120.days)
  Actuality.create!(title: "Les Concours de Mathraining", content: "Voici venus les Concours de Mathraining.", created_at: DateTime.now - 60.days)
end

# Create chapters
def create_chapters
  Section.all.each do |section|
    possible_prerequisites = Array.new
    num_levels = (section.fondation ? 1 : 3)
    for lev in 1..num_levels
      num_chapters = Random.rand(5) + (section.fondation ? 2 : 0)
      for i in 1..num_chapters
        chapter = Chapter.create(section:     section,
                                 name:        section.name + ", niv " + lev.to_s + ", num " + i.to_s,
                                 description: "Ce chapitre est essentiel pour la bonne compréhension de la " + section.name,
                                 level:       lev,
                                 position:    i,
                                 online:      true)
        
        # Prerequisites
        possible_prerequisites.each do |p|
          if Random.rand(3) == 0
            prereq = Prerequisite.new(chapter:      chapter,
                                      prerequisite: p)
            if prereq.valid?
              prereq.save
            end
          end
        end
        possible_prerequisites.push(chapter)
      end
    end
  end
end

# Create questions
def create_questions
  Chapter.all.each do |chapter|
    
    # Exercises
    num_exercises = 2 + Random.rand(3)
    cur_level = (chapter.section.fondation? ? 0 : 1)
    for k in 1..num_exercises
      is_decimal = (Random.rand(2) == 1)
      answer = (is_decimal ? Random.rand(101)/10.0 : Random.rand(101))
      Question.create(chapter:      chapter,
                      is_qcm:       false,
                      statement:    "Quelle est la valeur de " + answer.to_s + " ?",
                      decimal:      is_decimal,
                      answer:       answer,
                      position:     k,
                      online:       true,
                      explanation:  "C'est du bon sens !",
                      level:        cur_level,
                      many_answers: false)
      cur_level = cur_level+1 if !chapter.section.fondation? && Random.rand(2) == 1
    end
    
    # Qcms
    num_qcms = 2 + Random.rand(3)
    for k in 1..num_qcms
      many_answers = (Random.rand(2) == 1)
      if many_answers
        statement = "Quelles affirmations sont vraies ?"
        num_choices = (Random.rand(3) + 2)
      else
        x = Random.rand(3)
        y = Random.rand(3)
        statement = "Combien vaut " + x.to_s + " + " + y.to_s + " ?"
        num_choices = [x+y+1+Random.rand(3), 2].max
      end
      qcm = Question.create(chapter:      chapter,
                            is_qcm:       true,
                            statement:    statement,
                            many_answers: many_answers,
                            position:     num_exercises + k,
                            online:       true,
                            explanation:  "C'est évident !",
                            level:        cur_level,
                            decimal:      false,
                            answer:       0)
      cur_level = cur_level+1 if !chapter.section.fondation? && Random.rand(2) == 1
      
      for l in 1..num_choices
        if many_answers
          ok = (Random.rand(2) == 1)
          ans = (ok ? "Affirmation correcte" : "Affirmation incorrecte")
        else
          ans = (l-1).to_s
          ok = (x+y == (l-1))
        end
        Item.create(question: qcm,
                    ans:      ans,
                    position: l,
                    ok:       ok)
      end
    end
  end
end

# Create problems
def create_problems
  Section.where(:fondation => false).each do |section|
    for lev in 1..5
      num_problems = Random.rand(5)
      taken = Set.new
      for k in 1..num_problems
        while true
          id = Random.rand(100)
          if !taken.include?(id)
            break
          end
        end 
        taken.add(id)
        problem = Problem.create(section:     section,
                                 statement:   "Trouver la valeur de " + section.id.to_s + " + " + lev.to_s + " + " + k.to_s + ".",
                                 online:      true,
                                 level:       lev,
                                 explanation: "Il s'avère que la réponse est " + (section.id+lev+k).to_s + ".",
                                 number:      section.id*1000 + lev*100 + id,
                                 origin:      (Random.rand(5) == 0 ? "" : "La nuit des temps."))
                       
        # Prerequisites
        already = 0
        section.chapters.each do |c|
          if Random.rand(15-2*lev) < 2-already
            problem.chapters << c
          end
        end
      end
    end
  end
end

# Update sections (they already exist but we change the description and max points)
def update_sections
  Section.all.each do |section|
    section.update_attribute(:description, "Cette section est vraiment intéressante.")
    
    unless section.fondation
      max_points = 0
      section.chapters.each do |c|
        c.questions.each do |q|
          max_points += q.value
        end
      end
      section.problems.each do |p|
        max_points += p.value
      end
      section.update_attribute(:max_score, max_points)
    end
  end
end

# Create users, giving a temporary rating to store their "level"
def create_users
  # Get special countries for users
  num_countries = 3
  country = Array.new
  country[0] = Country.where(:name => "Belgique").first
  country[1] = Country.where(:name => "France").first
  country[2] = Country.where(:name => "Maroc").first
  
  # Root
  root = User.create(first_name:            "Root",
                     last_name:             "Root",
                     email:                 "root@root.com",
                     email_confirmation:    "root@root.com",
                     password:              "foobar",
                     password_confirmation: "foobar",
                     root:                  true,
                     admin:                 true,
                     year:                  1990,
                     country:               country[0],
                     created_at:            DateTime.now - 100.days)
  
  # Admin
  admin = User.create(first_name:            "Admin",
                      last_name:             "Admin",
                      email:                 "admin@admin.com",
                      email_confirmation:    "admin@admin.com",
                      password:              "foobar",
                      password_confirmation: "foobar",
                      root:                  false,
                      admin:                 true,
                      year:                  1993,
                      country:               country[1],
                      created_at:            DateTime.now - 90.days)
                      
  # Students
  for i in 1..20
    user_level = [Random.rand(151)-30, 2].max
    letter = "ABCDEFGHIJKLMNOPQRST"[i-1]
    mail = "user@user" + letter + ".com"
    wepion = Random.rand(2)
    group = ""
    if wepion
      x = Random.rand(3)
      group = "A" if x == 1
      group = "B" if x == 2
    end
    user = User.create(first_name:           "User",
                       last_name:            "User-" + letter,
                       email:                 mail,
                       email_confirmation:    mail,
                       password:              "foobar",
                       password_confirmation: "foobar",
                       root:                  false,
                       admin:                 false,
                       year:                  2000 + Random.rand(5),
                       country:               country[Random.rand(3)],
                       wepion:                wepion,
                       group:                 group,
                       rating:                user_level,
                       created_at:            DateTime.now - user_level.days)
  end
end

# Create solved questions for users
def create_solvedquestions
  User.where(:admin => false).each do |user|
    user_level = user.rating # Temporary level is stored as the rating, between 2 and 120
    start_time_by_chapter = Array.new

    Chapter.order(:level, :id).all.each do |c|
      # Check if user can see the chapter (and when he could start it)
      can_see = true
      min_start_time = user.created_at
      unless c.section.fondation
        c.prerequisites.each do |p|
          if !user.chapters.exists?(p.id)
            can_see = false
          else
            min_start_time = [min_start_time, start_time_by_chapter[p.id]].max
          end
        end
      end
      if !can_see
        next
      end
      
      start_time_by_chapter[c.id] = min_start_time + Random.rand([((DateTime.now.to_i - min_start_time.to_i)*0.4).to_i, 1].max).seconds
      completed = ((c.level-1)*40 + Random.rand(40) < user_level)
      all_correct = true
      c.questions.each do |q|
        t = start_time_by_chapter[c.id] + Random.rand(20*60).seconds
        if completed or Random.rand(130) < user_level # Correct
          Solvedquestion.create(question:        q,
                                user:            user,
                                nb_guess:        Random.rand(4)+1,
                                resolution_time: t)
        else
          all_correct = false
          if Random.rand(2) == 0 # Incorrect
            sq = Unsolvedquestion.create(question:        q,
                                         user:            user,
                                         guess:           (q.is_qcm ? 0.0 : q.answer + 1),
                                         nb_guess:        Random.rand(4)+1,
                                         last_guess_time: t)
            if q.is_qcm
              if q.many_answers # We say that user took all wrong choices
                q.items.each do |i|
                  if !i.ok
                    sq.items << i
                  end
                end
              else
                sq.items << q.items.where(:ok => false).first
              end
            end
          end
        end
      end
      if all_correct
        completed = true
      end
      if completed
        user.chapters << c
      end
    end
  end
end

# Update user ratings based on what they solved
def update_users_ratings
  User.where(:admin => false).each do |user|
    rating = 0
    rating_by_section = Array.new
    Section.select(:id).where(:fondation => false).each do |sec|
      rating_by_section[sec.id] = 0
    end
    
    user.solvedquestions.each do |q|
      unless q.question.chapter.section.fondation
        rating += q.question.value
        rating_by_section[q.question.chapter.section_id] += q.question.value
      end
    end
    
    user.solvedproblems.each do |p|
      rating += p.problem.value
      rating_by_section[p.problem.section_id] += p.problem.value
    end
    
    user.update_attribute(:rating, rating)
    user.pointspersections.each do |pps|
      pps.update_attribute(:points, rating_by_section[pps.section_id])
    end
  end
end

# Create submissions for users
def create_submissions
  max_rating = User.order(:rating).last.rating
  User.where(:admin => false).each do |user|
    if user.rating < 200
      next
    end
    user_level = 100*(user.rating-200)/(max_rating-200).to_f # Between 0 and 100
    last_question_solved_time = user.solvedquestions.order(:resolution_time).last.resolution_time
    
    completed_chapters = user.chapters.ids
    Problem.all.each do |problem|
      can_see_problem = true
      problem.chapters.ids.each do |prereq_id|
        if !completed_chapters.include?(prereq_id)
          can_see_problem = false
          break
        end
      end
      if !can_see_problem
        next
      end
      r = Random.rand(120)
      if r > user_level
        next
      end
      
      r2 = Random.rand(3)
      is_correct = (Random.rand(3) <= 1)
      submission_time = last_question_solved_time + Random.rand(DateTime.now.to_i - last_question_solved_time.to_i + 1).seconds
      corrected = Random.rand(30) > 0
      submission = Submission.create(user:              user,
                                     problem:           problem,
                                     content:           (is_correct ? "Ceci est une soumission correcte :-)" : "Ceci est incorrect :-("),
                                     status:            (corrected ? (is_correct ? 2 : 1) : 0),
                                     intest:            false,
                                     visible:           true,
                                     score:             -1,
                                     star:              corrected && is_correct && Random.rand(10) == 0,
                                     created_at:        submission_time,
                                     last_comment_time: submission_time)
      if corrected # Corrected
        correction_time = [submission_time + (300 + Random.rand(24*60*60)).seconds, DateTime.now].min
        Solvedproblem.create(user:            user,
                             problem:         problem,
                             submission:      submission,
                             resolution_time: submission_time,
                             correction_time: correction_time)
        corrector = (Random.rand(2) == 0 ? User.where(:admin => true).first : User.where(:admin => true).last)
        Correction.create(user:       corrector,
                          submission: submission,
                          content:    (is_correct ? "En effet c'est magnifique :-D" : "Effectivement c'est une catastrophe."),
                          created_at: correction_time)
        submission.update_attribute(:last_comment_time, correction_time)
        Following.create(user:       corrector,
                         submission: submission,
                         read:       true,
                         kind:       1,
                         created_at: correction_time)
      end
    end
  end
end

# Create some subjects and messages
def create_subjects
  # One important subject for everybody
  user = User.where(:root => true).first
  time = DateTime.now - 20.days
  category = Category.where(:name => "Mathraining").first
  subject = Subject.create(user:              user,
                           title:             "Questions relatives à Mathraining",
                           content:           "Si vous avez la moindre question, n'hésitez pas !",
                           important:         true,
                           category:          category,
                           created_at:        time,
                           last_comment_time: time,
                           last_comment_user: user)
  
  message = Message.create(subject:    subject,
                           user:       User.where(:admin => false).order(:created_at).last,
                           content:    "Je me demandais : comment devient-on correcteur ?",
                           created_at: DateTime.now - 5.days)
  subject.update(last_comment_time: message.created_at, last_comment_user: message.user)
  
  # One important subject for Wépion
  user = User.where(:root => true).first
  time = DateTime.now - 30.days
  category = Category.where(:name => "Wépion").first
  subject = Subject.create(user:              user,
                           title:             "Cours 2021-2022",
                           content:           "Voici l'horaire des cours de Wépion pour cette année.",
                           important:         true,
                           for_wepion:        true,
                           category:          category,
                           created_at:        time,
                           last_comment_time: time,
                           last_comment_user: user)
  
  message = Message.create(subject:    subject,
                           user:       User.where(:wepion => true).first,
                           content:    "Merci pour cette information précieuse.",
                           created_at: time + 2.hours)
  subject.update(last_comment_time: message.created_at, last_comment_user: message.user)
  
  # One important subject for correctors
  user = User.where(:root => false, :admin => true).first
  time = DateTime.now - 10.days
  category = Category.where(:name => "Mathraining").first
  subject = Subject.create(user:              user,
                           title:             "Instructions pour les correcteurs",
                           content:           "Voici les instructions pour les nouveaux correcteurs :-)",
                           important:         true,
                           for_correctors:    true,
                           category:          category,
                           created_at:        time,
                           last_comment_time: time,
                           last_comment_user: user)
                           
  # One subject about a chapter
  user = User.where(:admin => false).first
  time = user.created_at + 2.hours
  chapter = Chapter.first
  subject = Subject.create(user:              user,
                           title:             "Hein !?",
                           content:           "Je ne comprends rien à ce chapitre, quelqu'un peut me le réexpliquer en entier ?",
                           section:           chapter.section,
                           chapter:           chapter,
                           created_at:        time,
                           last_comment_time: time,
                           last_comment_user: user)
  
  message = Message.create(subject:    subject,
                           user:       User.where(:admin => true).first,
                           content:    "Relis le chapitre, tout simplement...",
                           created_at: time + 2.minutes)
  subject.update(last_comment_time: message.created_at, last_comment_user: message.user)
  
  # One subject about a question
  user = User.where(:admin => false).second
  time = user.created_at + 5.hours
  question = Section.where(:fondation => true).first.chapters.first.questions.first
  subject = Subject.create(user:              user,
                           title:             "Exercice incorrect ?",
                           content:           "Cet exercice me semble erroné, qu'en pensez-vous ?",
                           section:           question.chapter.section,
                           chapter:           question.chapter,
                           question:          question,
                           created_at:        time,
                           last_comment_time: time,
                           last_comment_user: user)
  
  message = Message.create(subject:    subject,
                           user:       User.where(:admin => false).third,
                           content:    "J'en pense que tu dis des sottises !",
                           created_at: time + 7.hours)
  subject.update(last_comment_time: message.created_at, last_comment_user: message.user)
end

# Update some statistics
def update_statistics
  Chapter.update_stats
  Question.update_stats
  Problem.update_stats
  Record.update
end

# Create visitor statistics
def create_visitor_statistics
  cur_day = Date.today - 100
  (0..99).each do |x|
    Visitor.create(date:      Date.today - 100 + x,
                   nb_users:  (x/10).to_i + Random.rand(1+(x/10).to_i),
                   nb_admins: Random.rand(3))
  end
end
