# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sciencewire_source_record do
    source_data 'MyText'
    pmid 1
    lock_version 1
    source_fingerprint 'MyString'
    is_active false
  end
end
