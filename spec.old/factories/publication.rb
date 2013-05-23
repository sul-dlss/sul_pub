FactoryGirl.define do
  factory :publication do
    title "How I learned Rails"
    author  "Jackson, Joe"
    year "1972"
    provenance "sciencewire"
    pub_hash {{title: "How I learned Rails", type: 'article', year: '1972', author: [{name: "Jackson, Joe"}]}}
    active true
    deleted false
  end
end