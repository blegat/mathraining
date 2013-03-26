FactoryGirl.define do
  factory :user do
    sequence(:first_name) { |n| "Jean#{n}" }
    sequence(:last_name) { |n| "Dupont#{n}" }
    sequence(:email) { |n| "person_#{n}@example.com" }
    password "foobar"
    password_confirmation "foobar"
    factory :admin do
      admin true
    end
  end
  factory :section do
    sequence(:name) { |n| "Section#{n}" }
    description "Description"
  end
  factory :chapter do
    sequence(:name) { |n| "Chapitre#{n}" }
    level 1
  end
  factory :prerequisite do
    association :chapter
    association :prerequisite, factory: :chapter
  end
  factory :theory do
    association :chapter
    title "a"
    content "a"
    sequence(:position) { |n| n }
  end

  # Qcm
  factory :qcm do
    association :chapter
    statement "a"
    sequence(:position) { |n| n }
  end
  factory :choice do
    association :qcm
    ans "42"
    ok false
  end

  factory :exercise do
    association :chapter
    statement "Foobar"
    decimal false
    answer 42
    sequence(:position) { |n| n }
  end
  factory :solvedexercise do
    association :exercise
    association :user
    correct false
    guess 42
    nb_guess 1
  end
  factory :problem do
    name "Foo"
    statement "Bar"
    association :chapter
    sequence(:position) { |n| n }
    online false
  end
  factory :submission do
    association :problem
    association :user
    content "Foobar"
  end
  factory :correction do
    association :submission
    association :user
    content "Foobar"
  end
end
