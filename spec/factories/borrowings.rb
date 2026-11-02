FactoryBot.define do
  factory :borrowing do
    book { nil }
    reader { nil }
    borrowed_at { "2026-11-02 18:32:10" }
    due_on { "2026-11-02" }
    returned_at { "2026-11-02 18:32:10" }
  end
end
