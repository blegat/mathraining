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
end
