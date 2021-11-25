FactoryGirl.define do
  # Actuality
  factory :actuality do
    title "titre"
    content "contenu"
  end
  
  # Category
  factory :category do
    sequence(:name) { |n| "Categorie #{n}" }
  end
  
  # Chapter
  factory :chapter do
    association :section
    sequence(:description) { |n| "Une description #{n}" }
    sequence(:name) { |n| "Chapitre #{n}" }
    level 1
  end
  
  # Color
  factory :color do
    pt 10000
    name "Nom"
    femininename "Nom feminin"
    color "#AAAAAA"
  end
  
  # Contest
  factory :contest do
    sequence(:number) { |n| n }
    sequence(:description) { |n| "Description du concours #{n}" }
    start_time DateTime.new(2020, 2, 3)
    end_time DateTime.new(2020, 3, 5)
    medal true
    status 3 # Finished
  end
  
  # Contestproblem
  factory :contestproblem do
    association :contest
    sequence(:number) { |n| n }
    sequence(:statement) { |n| "Énoncé du problème #{n}" }
    sequence(:origin) { |n| "Origine du problème #{n}" }
    start_time DateTime.new(2020, 2, 3)
    end_time DateTime.new(2020, 3, 5)
    status 4 # Corrected
    reminder_status 2 # No reminder needed
    # NB: The associated official contestsolution is created automatically
  end
  
  # Contestproblemcheck
  factory :contestproblemcheck do
    association :contestproblem
  end
  
  # Contestsolution
  factory :contestsolution do
    association :contestproblem
    association :user
    content "Voici ma solution."
    # NB: The associated contestcorrection is created automatically
  end
  
  # Contestscore
  factory :contestscore do
    association :contest
    association :user
    # rank, score, medal should be done manually
  end
  
  # Correction
  factory :correction do
    association :submission
    association :user
    content "Foobar"
  end
  
  # Country
  factory :country do
    sequence(:name) { |n| "Pays#{n}" }
    code "be" # Should be a value for which a flag exists!
  end
  
  # Following
  factory :following do
    association :submission
    association :user
    read false
  end
  
  # Item
  factory :item do
    association :question
    sequence(:ans) { |n| "42 + #{n}" }
    factory :item_correct do
      ok true
    end
    sequence(:position) { |n| n }
  end
  
  # Message
  factory :message do
    content "message"
    association :user
    association :subject
  end
  
  # Myfile
  factory :myfile do
    factory :subjectmyfile do
      association :myfiletable, factory: :subject
    end
    factory :messagemyfile do
      association :myfiletable, factory: :message
    end
    factory :submissionmyfile do
      association :myfiletable, factory: :submission
    end
    factory :correctionmyfile do
      association :myfiletable, factory: :correction
    end
    factory :contestsolutionmyfile do
      association :myfiletable, factory: :contestsolution
    end
    factory :contestcorrectionmyfile do
      association :myfiletable, factory: :contestcorrection # This factory doesn't exist so we should give the contestcorrection explicitly
    end
    factory :tchatmessagemyfile do
      association :myfiletable, factory: :tchatmessage # This factory doesn't exist so we should give the contestcorrection explicitly
    end
    before(:create) do |myfile|
      myfile.file.attach(io: File.open(Rails.root.join('spec', 'attachments', 'mathraining.png')), filename: 'mathraining.png', content_type: 'image/png')
    end
  end
  
  # Prerequisite
  factory :prerequisite do
    association :chapter
    association :prerequisite, factory: :chapter
  end
  
  # Privacypolicy
  factory :privacypolicy do
    sequence(:content) { |n| "Voici toute la politique de confidentialité #{n}" }
    sequence(:description) { |n| "Voici les modifications #{n}" }
    publication DateTime.current
    online false
  end
  
  # Problem
  factory :problem do
    association :section
    sequence(:statement) { |n| "Énoncé de problème #{n}" }
    level 1
    sequence(:number) { |n| n }
    online false
  end
  
  # Question
  factory :question do
    association :chapter
    sequence(:statement) { |n| "Énoncé d'exercice #{n}" }
    answer 0 # Mandatory (maybe it should not be)
    factory :exercise do
      is_qcm false
      decimal false
      answer 42
    end
    factory :exercise_decimal do
      is_qcm false
      decimal true
      answer 42.42
    end
    factory :qcm do
      is_qcm true
      many_answers false
    end
    factory :qcm_multiple do
      is_qcm true
      many_answers true
    end
    sequence(:position) { |n| n }
    level 1
    sequence(:explanation) { |n| "voici une explication #{ n }" }
  end
  
  # Section
  factory :section do
    sequence(:name) { |n| "Section#{n}" }
    description "Description"
    factory :fondation_section do
      fondation true
    end
  end
  
  # Solved question
  factory :solvedquestion do
    association :question, :factory => :exercise
    association :user
    correct false
    guess 42
    nb_guess 1
  end
  
  # Solved problem
  factory :solvedproblem do
    association :problem
    association :submission
    association :user
    resolutiontime DateTime.current
    truetime DateTime.current
  end
  
  # Subject
  factory :subject do
    sequence(:title) { |n| "Titre #{n}" }
    sequence(:content) { |n| "Contenu #{n}" }
    association :user
    lastcomment DateTime.current
    association :lastcomment_user, :factory => :user
    association :category
    chapter_id 0
    section_id 0
    question_id 0
    factory :admin_subject do
      admin true
    end
    factory :important_subject do
      important true
    end
  end
  
  # Submission
  factory :submission do
    association :problem
    association :user
    content "Interesting submission"
    lastcomment DateTime.current
  end
  
  # Theory
  factory :theory do
    association :chapter
    sequence(:title) { |n| "Mon titre #{n}" }
    sequence(:content) { |n| "Contenu #{n}" }
    sequence(:position) { |n| n }
  end
  
  # User
  factory :user do
    sequence(:first_name) { |n| "Jean#{(("a".."z").to_a)[(n/26).to_i]}#{(("a".."z").to_a)[n%26]}" }
    sequence(:last_name) { |n| "Dupont" }
    sequence(:email) { |n| "person_#{n}@example.com" }
    sequence(:email_confirmation) { |n| "person_#{n}@example.com" }
    association :country
    year 1992
    rating 0
    password "foobar"
    password_confirmation "foobar"
    consent_date DateTime.now
    last_policy_read true
    valid_name true
    factory :admin do
      admin true
    end
    factory :root do
      admin true
      root true
    end
    factory :corrector do
      corrector true
      rating 200
    end
    factory :advanced_user do
      rating 200
    end
  end
  
  # Virtualtest
  factory :virtualtest do
    duration 120
    number 25
    online false
  end
end
