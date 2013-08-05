module SulBib
  class AuthorshipAPI < Grape::API
    include Authz
    
    version 'v1', :using => :header, :vendor => 'sul', :format => :json
    format :json

    desc "Allows creating a new authorship/contribution record, or updating an existing record"
    content_type :json, "application/json"
    parser :json, BibJSONParser
    post do
      authorship_hash = params[:pub_hash]
      sul_author_id = authorship_hash[:sul_author_id]
      cap_profile_id = authorship_hash[:cap_profile_id]
      sul_pub_id = authorship_hash[:sul_pub_id]
      pmid = authorship_hash[:pmid]
      sciencewire_id = authorship_hash[:sw_id]
      featured = authorship_hash[:featured] || false
      visibility = authorship_hash[:visibility] || 'private'
      status = authorship_hash[:status] || 'approved'
      # FIRST GET THE AUTHOR
      if ! sul_author_id.blank?
        begin
          author = Author.find(sul_author_id)
        rescue ActiveRecord::RecordNotFound
          error!("The SUL author you've specified doesn't exist.", 404)
        end
      elsif ! cap_profile_id.blank?
          author = Author.where(cap_profile_id: cap_profile_id).first
          if author.nil?
              # todo check for the cap author in darryl's new api call.
            error!("The CAP author you've specified doesn't exist.", 404)
          end
          sul_author_id = author.id
      else
          error!("You haven't supplied an author identifier.", 404)
      end

      # NOW CHECK FOR AN EXISTING SUL PUBLICATION
      if !sul_pub_id.blank?
        begin
          sul_pub = Publication.find(sul_pub_id)
        rescue
          error!("The SUL publication you've specified doesn't exist.", 404)
        end
      elsif !pmid.blank?
        sul_pub = Publication.get_pub_by_pmid(pmid)
        if sul_pub.nil? then error!("The pmid you've specified can't be found either locally or at PubMed.", 404) end
      elsif !sciencewire_id.blank?
        sul_pub = Publication.get_pub_by_sciencewire_id(sciencewire_id)
        if sul_pub.nil? then error!("The ScienceWire publication you've specified can't be found either locally or at ScienceWire.", 404) end
      end

      #WE'VE NOW GOT THE PUB AND THE AUTHOR, GET THE CONTRIBUTION OR CREATE A NEW ONE, AND THEN UPDATE
      contrib_hash = {}
      contrib_hash[:status] = status
      contrib_hash[:visibility] = visibility
      contrib_hash[:featured] = featured
      contrib_hash[:cap_profile_id] = cap_profile_id unless cap_profile_id.blank?

      contrib = Contribution.where(author_id: sul_author_id, publication_id: sul_pub.id).first_or_create
      contrib.update_attributes(contrib_hash)

      sul_pub.sync_publication_hash_and_db
      sul_pub.pub_hash

    end # post end
  end #class end

end