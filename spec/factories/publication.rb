FactoryGirl.define do
  factory :publication do
    title "How I learned Rails"
    year "1972"
    pub_hash {{title: "How I learned Rails", type: 'article', year: '1972', author: [{name: "Jackson, Joe"}]}}
    active true
    deleted false
    publication_type "article"
  end
end