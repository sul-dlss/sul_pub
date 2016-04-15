FactoryGirl.define do

  sequence(:random_id) do |n|
    @random_ids ||= (10000..1000000).to_a.shuffle
    @random_ids[n]
  end

  factory :author do
    sunetid { FactoryGirl.generate(:random_id) }
    cap_profile_id { FactoryGirl.generate(:random_id) }
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
end
