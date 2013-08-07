require 'spec_helper'

describe Publication do
  let(:publication) { FactoryGirl.create :publication }
  let(:author) {FactoryGirl.create :author }
  
  let(:pub_hash) {{title: "some title", year: 1938, issn: '32242424', pages: '34-56', author: [{name: "jackson joe"}], authorship: [{sul_author_id: author.id, status: "denied", visibility: "public", featured: true} ]}}
  

  it "should rebuild authors and identifiers" do
    publication.pub_hash = pub_hash.dup
    publication.update_any_new_contribution_info_in_pub_hash_to_db(pub_hash)
    publication.save
    puts publication.reload.pub_hash.inspect

    expect(publication.pub_hash[:identifier].length).to be > 0
    expect(publication.pub_hash[:authorship].length).to be > 0



  end
end