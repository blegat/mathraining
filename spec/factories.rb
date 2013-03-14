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
  factory :qcm do
    association :chapter
    statement "a"
    sequence(:position) { |n| n }
  end
end
