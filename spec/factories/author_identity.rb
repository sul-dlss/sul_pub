# we use sequences so that we can get a variety of alternate identities
FactoryBot.define do
  factory :author_identity do
    sequence(:first_name)   { |n| "Alice#{n}" }
    sequence(:middle_name)  { |n| "Jim#{n}" }
    sequence(:last_name)    { |n| "Edler#{n}" }
    sequence(:email)        { |n| "alice.edler#{n}@stanford.edu" }
    institution             'Example University'
    start_date              { DateTime.current - 30.years }
    end_date                { DateTime.current }
    author
  end
end
