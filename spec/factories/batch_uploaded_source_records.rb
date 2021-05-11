# frozen_string_literal: true

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryBot.define do
  factory :batch_uploaded_source_record do
    sunet_id { 'MyString' }
    author_id { 1 }
    cap_profile_id { 1 }
    successful_import { false }
    bibtex_source_data { 'MyText' }
    source_fingerprint { 'MyString' }
    is_active { false }
    title { 'MyString' }
    year { 1 }
    batch_name { 'MyString' }
    error_message { 'MyText' }
  end
end
