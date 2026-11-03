FactoryBot.define do
  factory :borrowing do
    book
    reader
    borrowed_at { Time.current }
    due_on { borrowed_at.in_time_zone.to_date + 30 }
    returned_at { nil }

    trait :returned do
      returned_at { borrowed_at + 7.days }
    end
  end
end
