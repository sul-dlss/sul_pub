FactoryGirl.define do
  	factory :publication do
	    title "How I learned Rails"
	    year "1972"
	    pub_hash {{title: "How I learned Rails", type: 'article', year: '1972', author: [{name: "Jackson, Joe"}], authorship:[{sul_author_id: 2222, status: "denied", visibility: "public", featured: true}]}}
	    active true
	    deleted false
	    publication_type "article"
  	end

  	factory :publication_with_contributions, parent: :publication do
  		transient do
        	contributions_count 15
      	end
      	after(:create) do |publication, evaluator|
        	FactoryGirl.create_list(:contribution, evaluator.contributions_count, publication: publication)
      	end
	  end

    factory :pub_with_sw_id_and_pmid, parent: :publication do
      pmid 10048354
      sciencewire_id 42711845
    end

  

end