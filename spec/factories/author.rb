FactoryGirl.define do
  factory :author do
    sunetid 747_373
    active_in_cap true
    email 'alice.edler@stanford.edu'
    official_first_name 'Alice'
    official_last_name 'Edler'
    official_middle_name 'Jim'
    emails_for_harvest 'alice.edler@stanford.edu'
    cap_profile_id 2_343_433
  end

  factory :author_with_sw_pubs, parent: :author do
    id 33
  end

  factory :inactive_author, parent: :author do
    active_in_cap false
  end
end
