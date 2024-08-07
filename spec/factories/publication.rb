# frozen_string_literal: true

FactoryBot.define do
  factory :publication do
    title { 'How I learned Rails' }
    year { '1972' }
    pub_hash do
      {
        title:,
        type: publication_type,
        year:,
        author: [
          { name: 'Jackson, Joe' }
        ],
        authorship: [
          {
            sul_author_id: 2222,
            cap_profile_id: 3333,
            status: 'approved',
            visibility: 'public',
            featured: true
          }
        ]
      }
    end
    active { true }
    deleted { false }
    publication_type { 'article' }
  end

  factory :manual_publication, parent: :publication do
    pub_hash do
      {
        provenance: 'cap',
        identifier: [
          { type: 'isbn', id: '1177188188181' },
          { type: 'doi', id: '18819910019', url: 'http://doi:18819910019' }
        ],
        type: publication_type
      }
    end
  end

  factory :wos_publication, parent: :publication do
    pub_hash do
      {
        provenance: 'wos',
        type: publication_type
      }
    end
  end

  factory :publication_with_contributions, parent: :publication do
    transient do
      contributions_count { 15 }
    end
    after(:create) do |publication, evaluator|
      FactoryBot.create_list(:contribution, evaluator.contributions_count, publication:)
    end
  end

  factory :pub_with_sw_id, parent: :publication do
    sciencewire_id { 42_711_845 }
  end

  factory :pub_with_sw_id_and_pmid, parent: :pub_with_sw_id do
    pmid { 10_048_354 }
  end

  factory :pub_with_pmid_and_pub_identifier, parent: :publication do
    pmid { 10_048_354 }
    after(:create) do |publication, _evaluator|
      create(:publication_identifier,
             publication:,
             identifier_type: 'PMID',
             identifier_value: '10048354')
    end
  end

  factory :publication_without_author, parent: :publication do
    pub_hash do
      {
        title:,
        type: publication_type,
        year:,
        author: [],
        authorship: []
      }
    end
  end
end
