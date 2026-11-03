FactoryBot.define do
  factory :reader do
    sequence(:card_number) { |n| format("%06d", n) }
    full_name { "John Doe" }
    sequence(:email) { |n| "reader#{n}@example.com" }
  end
end
