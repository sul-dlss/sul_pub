# frozen_string_literal: true

FactoryBot.define do
  sequence(:random_id) do |n|
    @random_ids ||= {}
    @random_ids[n] ||= begin
      x = nil
      while x.nil?
        i = SecureRandom.random_number(990_000) + 10_000
        x = i unless @random_ids.values.include?(i)
      end
      x
    end
  end

  sequence(:random_string) do |n|
    @random_strings ||= {}
    @random_strings[n] ||= begin
      x = nil
      while x.nil?
        i = SecureRandom.hex
        x = i unless @random_strings.values.include?(i)
      end
      x
    end
  end

  factory :author do
    sunetid { FactoryBot.generate(:random_id) }
    cap_profile_id { FactoryBot.generate(:random_id) }
    university_id { FactoryBot.generate(:random_id) }
    california_physician_license { FactoryBot.generate(:random_string) }
    active_in_cap { true }
    email { 'alice.edler@stanford.edu' }
    official_first_name { 'Alice' }
    official_last_name { 'Edler' }
    official_middle_name { 'Jim' }
    preferred_first_name { 'Alice' }
    preferred_last_name { 'Edler' }
    preferred_middle_name { 'Jim' }
    emails_for_harvest { 'alice.edler@stanford.edu' }
    sequence(:orcidid, 1000) { |n| "https://orcid.org/0000-0000-0000-#{n}" }

    trait :blank_first_name do
      official_first_name { '' }
      preferred_first_name { '' }
    end

    trait :blank_orcid do
      orcidid { nil }
    end

    trait :valid_orcid do
      orcidid { 'https://orcid.org/0000-0003-3859-2905' }
    end

    trait :space_first_name do
      official_first_name { ' ' }
      preferred_first_name { ' ' }
    end

    trait :period_first_name do
      official_first_name { '.' }
      preferred_first_name { '.' }
    end

    trait :or_first_name do
      official_first_name { 'Or' }
      preferred_first_name { 'Or' }
    end

    trait :not_last_name do
      official_first_name { 'Not' }
      preferred_first_name { 'Not' }
    end

    trait :nil_first_name do
      official_first_name { nil }
      preferred_first_name { nil }
    end

    trait :nil_last_name do
      official_last_name { nil }
      preferred_last_name { nil }
    end

    trait :with_no_results do
      official_first_name { 'SomeUnusualFirstName' }
      preferred_first_name { 'SomeUnusualFirstName' }
      official_last_name { 'SomeUnusualLastName' }
      preferred_last_name { 'SomeUnusualLastName' }
    end
  end

  factory :author_with_alternate_identities, parent: :author do
    transient do
      alt_count { 1 } # default number of alternate identities to create
    end
    after(:create) do |author, evaluator|
      evaluator.alt_count.times do
        create(:author_identity, author:)
      end
    end

    trait :or_first_name do
      official_first_name { 'Or' }
      preferred_first_name { 'Or' }
    end
  end

  # Public data from
  # - https://stanfordwho.stanford.edu
  # - https://profiles.med.stanford.edu/russ-altman
  factory :russ_altman, parent: :author do
    sunetid { 'altman' }
    active_in_cap { true }
    cap_import_enabled { true }
    official_first_name { 'Russ' }
    official_last_name { 'Altman' }
    official_middle_name { 'Biagio' }
    preferred_first_name { 'Russ' }
    preferred_last_name { 'Altman' }
    preferred_middle_name { 'Biagio' }
    email { 'Russ.Altman@stanford.edu' }
    emails_for_harvest { 'Russ.Altman@stanford.edu' }
    orcidid { 'https://orcid.org/0000-0003-3859-2905' }
    # create some `author.author_identities`
    after(:create) do |author, _evaluator|
      create(:author_identity,
             author:,
             first_name: 'R',
             middle_name: 'B',
             last_name: 'Altman',
             email: nil,
             institution: 'Stanford University')
      create(:author_identity,
             author:,
             first_name: 'Russ',
             middle_name: nil,
             last_name: 'Altman',
             email: nil,
             institution: nil)
    end
  end
end
