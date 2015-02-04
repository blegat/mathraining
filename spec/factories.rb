FactoryGirl.define do
  # User
  factory :user do
    sequence(:first_name) { |n| "Jean#{n}" }
    sequence(:last_name) { |n| "Dupont#{n}" }
    sequence(:email) { |n| "person_#{n}@example.com" }
    password "foobar"
    password_confirmation "foobar"
    factory :admin do
      admin true
      root false
    end
  end
  # Section
  factory :section do
    sequence(:name) { |n| "Section#{n}" }
    description "Description"
  end
  # Chapter
  factory :chapter do
    sequence(:name) { |n| "Chapitre#{n}" }
    level 1
  end
  # Prerequisite
  factory :prerequisite do
    association :chapter
    association :prerequisite, factory: :chapter
  end
  # Theory
  factory :theory do
    association :chapter
    title "titre"
    content "contenu"
    sequence(:position) { |n| n }
  end

  # Qcm
  factory :qcm do
    association :chapter
    statement "a"
    sequence(:position) { |n| n }
  end
  # Choice
  factory :choice do
    association :qcm
    ans "42"
    ok false
  end
  
  # Exercise
  factory :exercise do
    association :chapter
    statement "Foobar"
    decimal false
    answer 42
    sequence(:position) { |n| n }
    level 1
    explanation "explication"
  end
  # Solved exercise
  factory :solvedexercise do
    association :exercise
    association :user
    correct false
    guess 42
    nb_guess 1
  end
  # Problem
  factory :problem do
    statement "Foobar"
    level 1
    online false
  end
  # Solved problem
  factory :solvedproblem do
    association :problem
    association :user
  end
  # Submission
  factory :submission do
    association :problem
    association :user
    content "Foobar"
  end
  # Correction
  factory :correction do
    association :submission
    association :user
    content "Foobar"
  end
  # Following
  factory :following do
    association :submission
    association :user
    read false
  end
  
  # Actualities
  factory :actuality do
    title "titre"
    content "contenu"
  end
  # Color
  factory :color do
    pt 0
    name "Nom"
    femininename "Nom feminin"
    color "#AAAAAA"
    font_color "#BBBBBB"
  end
  # Subject
  factory :subject do
    title "Titre"
    content "Contenu"
    association :user
    admin :false
    important :false
    wepion :false
    lastcomment DateTime.current
  end
  # Message
  factory :message do
    content "message"
    association :user
    association :subject
  end
end
