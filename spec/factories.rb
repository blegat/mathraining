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
    sequence(:author) { |n| "Auteur #{n}" }
    level 1
  end
  
  # Color
  factory :color do
    pt 10000
    name "Nom"
    femininename "Nom feminin"
    color "#AAAAAA"
    dark_color "#CCCCCC"
  end
  
  # Contest
  factory :contest do
    sequence(:number) { |n| n }
    sequence(:description) { |n| "Description du concours #{n}" }
    start_time DateTime.new(2020, 2, 3)
    end_time DateTime.new(2020, 3, 5)
    medal true
    status :completed
  end
  
  # Contestproblem
  factory :contestproblem do
    association :contest
    sequence(:number) { |n| n }
    sequence(:statement) { |n| "Énoncé du problème #{n}" }
    sequence(:origin) { |n| "Origine du problème #{n}" }
    start_time DateTime.new(2020, 2, 3)
    end_time DateTime.new(2020, 3, 5)
    status :corrected
    reminder_status :all_reminders_sent
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
  
  # Contestcorrection: Avoid creating it directly! Create Contestsolution instead!
  factory :contestcorrection do
    association :contestsolution
    content "Voici ma correction"
  end
  
  # Contestscore
  factory :contestscore do
    association :contest
    association :user
    medal :undefined_medal
    # rank and score should be done manually
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
  
  # Externalsolution
  factory :externalsolution do
    association :problem
    sequence(:url) { |n| "https://www.source#{n}.com" }
  end
  
  # Extract
  factory :extract do
    association :externalsolution
    sequence(:text) { |n| "Extrait #{n} extérieur" }
  end
  
  # Faq
  factory :faq do
    sequence(:question) { |n| "C'est quoi #{n} Mathraining ?" }
    sequence(:answer) { |n| "Un merveilleux #{n} site." }
    sequence(:position) { |n| n }
  end
  
  # Following
  factory :following do
    association :submission
    association :user
    read false
    kind :first_corrector
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
      association :myfiletable, factory: :tchatmessage # This factory doesn't exist so we should give the tchatmessage explicitly
    end
    before(:create) do |myfile|
      myfile.file.attach(io: File.open(Rails.root.join('spec', 'attachments', 'mathraining.png')), filename: 'mathraining.png', content_type: 'image/png')
    end
  end
  
  # Picture
  factory :picture do
    association :user
    before(:create) do |picture|
      picture.image.attach(io: File.open(Rails.root.join('spec', 'attachments', 'mathraining.png')), filename: 'mathraining.png', content_type: 'image/png')
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
    publication_time DateTime.now
    online false
  end
  
  # Problem
  factory :problem do
    association :section
    sequence(:statement) { |n| "Énoncé de problème #{n}" }
    level 1
    sequence(:number) { |n| n }
    sequence(:origin) { |n| "Origine #{n}" }
    online false
  end
  
  # Puzzle
  factory :puzzle do
    sequence(:statement) {|n| "Ce puzzle #{n} est difficile"}
    code "AB123"
    sequence(:position) {|n| n}
    sequence(:explanation) {|n| "Il fallait faire #{n} opérations."}
  end
  
  # Puzzleattempt
  factory :puzzleattempt do
    association :puzzle
    association :user
    code "BC234"
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
    sequence(:explanation) { |n| "Voici une explication #{ n }" }
  end
  
  # Sanction
  factory :sanction do
    association :user
    sanction_type :ban
    start_time DateTime.now
    duration 14
    sequence(:reason) { |n| "Banni pour #{n} plagiats jusqu'au [DATE]." }
  end
  
  # Saved reply
  factory :savedreply do
    section_id 0
    problem_id 0
    user_id 0
    approved true
    sequence(:content) { |n| "Réponse enregistrée numéro #{n} !" }
  end
  
  # Section
  factory :section do
    sequence(:name) { |n| "Section #{n}" }
    sequence(:abbreviation) { |n| "Sec. #{n}" }
    sequence(:short_abbreviation) { |n| "S. #{n}" }
    sequence(:initials) { |n| "S" }
    description "Description"
    factory :fondation_section do
      fondation true
    end
  end
  
  # Solved question
  factory :solvedquestion do
    association :question, :factory => :exercise
    association :user
    nb_guess 1
    resolution_time DateTime.now
  end
  
  # Solved problem
  factory :solvedproblem do
    association :problem
    association :submission
    association :user
    correction_time DateTime.now
    resolution_time DateTime.now
  end
  
  # Star proposal
  factory :starproposal do
    association :submission
    association :user
    sequence(:reason) { |n| "Ma raison numéro #{n} !" }
    status :waiting_treatment
  end
  
  # Subject
  factory :subject do
    sequence(:title) { |n| "Titre #{n}" }
    association :category
    chapter_id nil
    section_id nil
    question_id nil
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
    sequence(:content) { |n| "Interesting submission #{n}" }
  end
  
  # Suspicion
  factory :suspicion do
    association :submission
    association :user
    sequence(:source) { |n| "http://www.google_#{n}.com" }
    status :waiting_confirmation
  end
  
  # Theory
  factory :theory do
    association :chapter
    sequence(:title) { |n| "Mon titre #{n} saugrenu" }
    sequence(:content) { |n| "Contenu #{n}" }
    sequence(:position) { |n| n }
  end
  
  # Unsolved question
  factory :unsolvedquestion do
    association :question, :factory => :exercise
    association :user
    guess 42
    nb_guess 1
    last_guess_time DateTime.now
  end
  
  # User
  factory :user do
    sequence(:first_name) { |n| "Jean#{(("a".."z").to_a)[(n/(26*26)).floor]}#{(("a".."z").to_a)[(n/26).floor%26]}#{(("a".."z").to_a)[n%26]}" }
    sequence(:last_name) { |n| "Dupont" }
    sequence(:email) { |n| "person_#{n}@example.com" }
    sequence(:email_confirmation) { |n| "person_#{n}@example.com" }
    association :country
    year 1992
    rating 0
    password "Foobar22"
    password_confirmation "Foobar22"
    password_strength :strong_password
    consent_time DateTime.now
    last_policy_read true
    accepted_code_of_conduct true
    valid_name true
    factory :admin do
      role :administrator
    end
    factory :root do
      role :root
    end
    factory :corrector do
      corrector true
      sequence(:rating) { |n| 200+n }
    end
    factory :advanced_user do
      sequence(:rating) { |n| 200+n }
    end
  end
  
  # Virtualtest
  factory :virtualtest do
    duration 120
    number 25
    online false
  end
end
