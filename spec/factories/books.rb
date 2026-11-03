FactoryBot.define do
  factory :book do
    sequence(:serial_number) { |n| format("%06d", n) }
    title { "Clean Code" }
    author { "Robert C. Martin" }
  end
end
