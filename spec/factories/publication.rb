FactoryGirl.define do
  factory :publication do
    title 'How I learned Rails'
    year '1972'
    pub_hash do
      {
        title: 'How I learned Rails',
        type: 'article',
        year: '1972',
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
    active true
    deleted false
    publication_type 'article'
  end

  factory :publication_with_contributions, parent: :publication do
    transient do
      contributions_count 15
    end
    after(:create) do |publication, evaluator|
      FactoryGirl.create_list(:contribution, evaluator.contributions_count, publication: publication)
    end
  end

  factory :pub_with_sw_id, parent: :publication do
    sciencewire_id 42_711_845
  end

  factory :pub_with_sw_id_and_pmid, parent: :pub_with_sw_id do
    pmid 10_048_354
  end
end
