FactoryBot.define do
  sequence(:random_id) do |n|
    @random_ids ||= (10_000..1_000_000).to_a.shuffle
    @random_ids[n]
  end

  factory :author do
    sunetid { FactoryBot.generate(:random_id) }
    cap_profile_id { FactoryBot.generate(:random_id) }
    active_in_cap true
    email 'alice.edler@stanford.edu'
    official_first_name 'Alice'
    official_last_name 'Edler'
    official_middle_name 'Jim'
    preferred_first_name 'Alice'
    preferred_last_name 'Edler'
    preferred_middle_name 'Jim'
    emails_for_harvest 'alice.edler@stanford.edu'
  end

  factory :author_with_sw_pubs, parent: :author do
    id 33
  end

  factory :inactive_author, parent: :author do
    active_in_cap false
  end

  factory :author_with_alternate_identities, parent: :author do
    transient do
      alt_count 1 # default number of alternate identities to create
    end
    after(:create) do |author, evaluator|
      evaluator.alt_count.times do
        create(:author_identity, author: author)
      end
    end
  end
end
