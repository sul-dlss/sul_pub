FactoryGirl.define do
  factory :author do
    sunetid 747373
    active_in_cap true
    email "alice.edler@stanford.edu"
    official_first_name "John"
    official_last_name "Jones"
    official_middle_name "Jim"
    emails_for_harvest "alice.edler@stanford.edu"
  end

  factory :author_with_sw_pubs, parent: :author do
      	id 33
	end

  factory :inactive_author, parent: :author do
    active_in_cap false
  end
end