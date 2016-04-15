FactoryGirl.define do
  factory :author_identity do
    first_name       'Jane'
    middle_name      'R'
    last_name        'Smith'
    sequence(:email) { |n| "jrsmith#{n}@example.com" }
    institution      'Example University'
    start_date       { DateTime.current - 1.year }
    end_date         { DateTime.current }
    author
  end
end
