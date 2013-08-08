module SulBib
  class AuthorshipAPI < Grape::API
    
    version 'v1', :using => :header, :vendor => 'sul', :format => :json
    format :json

    desc "Allows creating a new authorship/contribution record, or updating an existing record"
    content_type :json, "application/json"
    parser :json, AuthorshipJSONParser
    params do
      requires :author, type: Hash, desc: "The JSON body must contain either a sul_author_id or cap_profile_id"
      requires :publication, type: Hash, desc: "The JSON body must contain wither a sul_pub_id, pmid, or sw_id"
      optional :featured, type: Boolean, default: false, desc: "The JSON body should indicate if the contribution is featured"
      optional :visibility, type: String, default: 'private', desc: "The JSON body should indicate if the contribution is visible"
      optional :status, type: String, default: 'approved', desc: "The JSON body should indicate if the contribution is approved"
    end
    post do
      # FIRST GET THE AUTHOR
      author = if params[:author][:id]
        begin
          Author.find(params[:author][:id])
        rescue ActiveRecord::RecordNotFound
          error!("The SUL author you've specified doesn't exist.", 500)
        end
      elsif params[:author][:cap_profile_id]
          a = Author.where(cap_profile_id: params[:author][:cap_profile_id]).first
          if a.nil?
              # todo check for the cap author in darryl's new api call.
            error!("The CAP author you've specified doesn't exist.", 400)
          end
          a
      else
          error!("You haven't supplied an author identifier.", 400)
      end

      # NOW CHECK FOR AN EXISTING SUL PUBLICATION
      sul_pub = if params[:publication][:id]
        begin
          Publication.find(params[:publication][:id])
        rescue
          error!("The SUL publication you've specified doesn't exist.", 400)
        end
      elsif params[:publication][:pmid]
        p = Publication.find_or_create_by_pmid(params[:publication][:pmid])
        if p.nil? then error!("The pmid you've specified can't be found either locally or at PubMed.", 400) end
        p
      elsif params[:publication][:sciencewire_id]
        p = Publication.find_or_create_by_sciencewire_id(params[:publication][:sciencewire_id])
        if p.nil? then error!("The ScienceWire publication you've specified can't be found either locally or at ScienceWire.", 400) end
        p
      else
        error!("You haven't supplied a publication identifier", 400)
      end

      #WE'VE NOW GOT THE PUB AND THE AUTHOR, GET THE CONTRIBUTION OR CREATE A NEW ONE, AND THEN UPDATE
      contrib_hash = {}
      contrib_hash[:status] = params[:status]
      contrib_hash[:visibility] = params[:visibility]
      contrib_hash[:featured] = params[:featured]

      sul_pub.add_or_update_author(author, contrib_hash)
      begin
        sul_pub.save!
      rescue ActiveRecord::RecordNotSaved => e
        error!(e.inspect, 500)
      end
      sul_pub.pub_hash
    end # post end
  end #class end

end