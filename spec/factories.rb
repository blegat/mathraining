FactoryGirl.define do
	factory :user do
		sequence(:fname) { |n| "Fname #{n}" }
		sequence(:lname) { |n| "Lname#{n}" }
		sequence(:email) { |n| "person_#{n}@example.com" }
		password "foobar"
		password_confirmation "foobar"
        factory :admin do
          admin true
        end
	end
end
