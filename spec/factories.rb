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
    description "Une description"
    sequence(:name) { |n| "Chapitre #{n}" }
    level 1
  end
  
  # Item
  factory :item do
    association :question
    ans "42"
    ok false
    sequence(:position) { |n| n }
  end
  
  # Color
  factory :color do
    pt 10000
    name "Nom"
    femininename "Nom feminin"
    color "#AAAAAA"
    font_color "#BBBBBB"
  end
  
  # Correction
  factory :correction do
    association :submission
    association :user
    content "Foobar"
  end
  
  factory :country do
    name "Lune"
    code "lu"
  end
  
  # Question
  factory :question do
    association :chapter
    statement "Foobar"
    decimal false
    many_answers false
    answer 42
    sequence(:position) { |n| n }
    level 1
    explanation "explication"
  end
  
  # Following
  factory :following do
    association :submission
    association :user
    read false
  end
  
  # Message
  factory :message do
    content "message"
    association :user
    association :subject
  end
  
  # Prerequisite
  factory :prerequisite do
    association :chapter
    association :prerequisite, factory: :chapter
  end
  
  # Problem
  factory :problem do
    association :section
    statement "Foobar"
    level 1
    online false
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
    association :question
    association :user
    correct false
    guess 42
    nb_guess 1
  end
  
  # Solved problem
  factory :solvedproblem do
    association :problem
    association :user
  end
  
  # Subject
  factory :subject do
    title "Titre"
    content "Contenu"
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
      important false
    end
  end
  
  # Submission
  factory :submission do
    association :problem
    association :user
    content "Foobar"
  end
  
  # Theory
  factory :theory do
    association :chapter
    title "titre"
    content "contenu"
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
    factory :admin do
      admin true
      root false
    end
    factory :root do
      admin true
      root true
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
