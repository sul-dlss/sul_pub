module SulBib

#validator for year

class YearCheck < Grape::Validations::Validator
  def validate_param!(attr_name, params)
    unless (1000..2100).include?(params[attr_name])
      throw :error, :status => 400, :message => "#{attr_name} must be four digits long and fall between 1000 and 2100"
    end
  end
end

 module BibJSONParser
    def self.call(object, env) 
      {:pub_hash => JSON.parse(object)}
    end     
  end

  class API_samples < Grape::API
   # version 'v1', :using => :header, :vendor => 'sul', :format => :json
   # format :json
    #rescue_from :all, :backtrace => true
    
    get(:get_pub_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'get_pub_out.json')) }
    get(:get_pubs_out) { IO.read(Rails.root.join('app', 'data', 'api_samples', 'get_pubs_out.json')) }
    get(:get_source_lookup_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'get_source_lookup_out.json')) }
    get(:post_pub_in_json) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'post_pub_in.json'))}
    get(:post_pub_in_bibtex) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'post_pub_in.bibtex'))}
    get(:post_pub_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'post_pub_out.json'))}
    get(:post_pubs_in) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'post_pubs_in.json'))}
    get(:post_pubs_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'post_pubs_out.json'))}
    get(:put_pub_in) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'put_pub_in.json'))}
    get(:put_pub_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'put_pub_out.json'))}
    get(:delete_pub_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'delete_pub_out.json'))}
  end

 # class API_authors < Grape::API
  #  version 'v1', :using => :header, :vendor => 'sul', :format => :json
  #  format :json
  #  get do
  #    error!('Unauthorized', 401) unless env['HTTP_CAPKEY'] == '***REMOVED***'
   #   Author.all(:include => :population_memberships, :conditions => "population_memberships.population_name = 'cap'")
   # end
  #end

  class AuthorshipAPI < Grape::API
    version 'v1', :using => :header, :vendor => 'sul', :format => :json
    format :json

    # ALLOWS CREATING A NEW AUTHORSHIP (CONTRIBUTION) RECORD, OR UPDATING AN EXISTING RECORD
    content_type :json, "application/json"
    parser :json, BibJSONParser
    post do
      #puts params[:pub_hash].to_s
      error!('Unauthorized', 401) unless env['HTTP_CAPKEY'] == '***REMOVED***'
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
      unless cap_profile_id.blank? then contrib_hash[:cap_profile_id] = cap_profile_id end

      contrib = Contribution.where(author_id: sul_author_id, publication_id: sul_pub.id).first_or_create
      contrib.update_attributes(contrib_hash)
  
      sul_pub.sync_publication_hash_and_db
      sul_pub.pub_hash

    end # post end
  end #class end

  class API < Grape::API

    version 'v1', :using => :header, :vendor => 'sul', :cascade => false
    format :json
    #rescue_from :all, :backtrace => true
    
    #rescue_from :all do |e|
    #    rack_response({ :message => "rescued from #{e.class.name}" })
    #end

helpers do
  def wrap_as_bibjson_collection(description, query, records, page, per_page)
    metadata = {
          _created: Time.now.iso8601,  
          description: description, 
          format: "BibJSON",  
          license: "some licence", 
          query: query, 
          records:  records.count.to_s
        }
    metadata[:page] = page || 1
    metadata[:per_page] = per_page || "all"
    {
        metadata: metadata, 
        records: records
    }
  end 
end


params do
  optional :year, type: Integer, :year_check => true, desc: "Four digit year."
  requires :title
  optional :source
end

get :sourcelookup do
    error!('Unauthorized', 401) unless env['HTTP_CAPKEY'] == '***REMOVED***'
      all_matching_records = []

      # set source to all sources if param value is blank     
      source = params[:source] || Settings.manual_source + '+' + Settings.sciencewire_source
      last_name = params[:lastname]
      first_name = params[:firstname]
      middle_name = params[:middlename]
      title = params[:title]
      year = params[:year]
      max_rows = params[:maxrows] || 20

      sources = source.split('+')

      if source.include?(Settings.sciencewire_source)
        all_matching_records = ScienceWireClient.new.query_sciencewire_for_publication(first_name, last_name, middle_name, title, year, max_rows)      
      end

      if source.include?(Settings.manual_source)
        
        user_submitted_source_records = UserSubmittedSourceRecord.arel_table

        unless year.blank?
        results = UserSubmittedSourceRecord.where(user_submitted_source_records[:title].matches("%#{title}%")).
          where(user_submitted_source_records[:year].eq(year))
        else
          results = UserSubmittedSourceRecord.where(user_submitted_source_records[:title].matches("%#{title}%"))
        end
        results.each {|source_record| all_matching_records << source_record.publication.pub_hash }
      end

      wrap_as_bibjson_collection("Search results from requested sources: " + source, env["ORIGINAL_FULLPATH"], all_matching_records, nil, nil)
    
    end

#:include => :population_membership,
#:conditions => "population_memberships.population_name = '" + population + "' AND publications.updated_at > '" + DateTime.parse(changedSince).to_s + "'"      
    
    # GET ALL PUBS, PAGED IF REQUESTD, OR FOR AN AUTHOR IF REQUESTED.       
    get do
      error!('Unauthorized', 401) unless env['HTTP_CAPKEY'] == '***REMOVED***'
      matching_records = []
      population = params[:population] || Settings.cap_population_name
      changedSince = params[:changedSince] || "1000-01-01"
      capProfileId = params[:capProfileId]
      capActive = params[:capActive]
      page = params[:page] || 1
      
      population.downcase!
      last_changed = DateTime.parse(changedSince).to_s
      if ! capActive.blank?
        capActive = capActive.downcase == 'true' ? '1' : '0'
        query_string = 'authors.active_in_cap = ' + capActive + ' and publications.updated_at > ?'
      else
        query_string = 'publications.updated_at > ?'
      end
      
      if capProfileId.blank?
        per = params[:per] || 100
        description = "Records that have changed since " + changedSince
        #if page.blank?       
         # Publication.joins(:contributions => :author).
         #   where(query_string, last_changed).
         #   group('publications.id').find_each do | publication |
         #     matching_records << publication.pub_hash 
         # end         
        #else
         matching_records = Publication.joins(:contributions => :author).
              where(query_string, last_changed).
              order('publications.id').
              group('publications.pub_hash').
              page(page).
              per(per).pluck(:pub_hash)
              
        #end 
      else
      #  page = page || 1
        per = per || nil
        author = Author.where(cap_profile_id: capProfileId).first
        if author.nil?
          error!({ "error" => "No such author", "detail" => "You've specified a non-existant author." }, 404)
        else
          description = "All known publications for CAP profile id " + capProfileId
          matching_records = author.contributions.order(:id).page(page).per(per).collect { |contr| contr.publication.pub_hash }
        end
      end
      wrap_as_bibjson_collection(description, env["ORIGINAL_FULLPATH"].to_s, matching_records, page, per)
    end

    # CALL TO ADD A NEW MANUAL PUBLICATION
    content_type :json, "application/json"
    parser :json, BibJSONParser
    post do     
      
      error!('Unauthorized', 401) unless env['HTTP_CAPKEY'] == '***REMOVED***'  
      request_body_unparsed = env['api.request.input']
      pub_hash = params[:pub_hash]
     # Rails.logger.debug "Incoming bibjson post attributes hash: #{pub_hash}"
      fingerprint = Digest::SHA2.hexdigest(request_body_unparsed)
      existingRecord = UserSubmittedSourceRecord.where(source_fingerprint: fingerprint).first
      unless existingRecord.nil?  
          # the GRAPE redirect method issues a 303 (when original request is not a get, and a 302 for a get) 
          # and sets the location header to the specified url
          # So, this next lines return 303 with location equal to the pub's uri
          redirect env["REQUEST_URI"] + "/" + existingRecord.publication_id.to_s
      else 
        if pub_hash[:authorship].nil? || ! Contribution.valid_authorship_hash?(pub_hash[:authorship])
          error!("You haven't supplied a valid authorship record.", 406) 
        end
        pub = Publication.build_new_manual_publication(Settings.cap_provenance, pub_hash, request_body_unparsed)
        header "Location", env["REQUEST_URI"].to_s + "/" + pub.id.to_s
        pub.pub_hash
      end
    
    end

    # CALL TO UPDATE A NEW MANUAL PUBLICATION
    content_type :json, "application/json"
    parser :json, BibJSONParser
    put ':id' do

      error!('Unauthorized', 401) unless env['HTTP_CAPKEY'] == '***REMOVED***'
      #the last known etag must be sent in the 'if-match' header, returning 412 “Precondition Failed” if etags don't match, 
      #and a 428 "Precondition Required" if the if-match header isn't supplied
      
      begin
          pub = Publication.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          error!({ "error" => "No such publication", "detail" => "You've requested a non-existant publication." }, 404)
        end

      if pub.deleted 
        error!("Gone - old resource probably deleted.", 410)
      elsif (!pub.sciencewire_id.blank?) || (!pub.pmid.blank?)
        error!({ "error" => "This record may not be modified.  If you had originally entered details for the record, it has been superceded by a central record.", "detail" => "missing widget" }, 403)
      elsif env["HTTP_IF_MATCH"].blank?
        error!("Precondition Required", 428) 
      elsif env["HTTP_IF_MATCH"] != pub.pub_hash[:last_updated]
        error!("Precondition Failed", 412) 
      elsif params[:pub_hash][:authorship].nil? || ! Contribution.valid_authorship_hash?(params[:pub_hash][:authorship])
        error!("You haven't supplied a valid authorship record.", 406) 
      else
        original_source = env['api.request.input']
        pub.update_manual_pub_from_pub_hash(params[:pub_hash], Settings.cap_provenance, original_source)
        pub.pub_hash
      end
    end

    # GET A SINGLE RECORD
    get ':id' do
      error!('Unauthorized', 401) unless env['HTTP_CAPKEY'] == '***REMOVED***'
      begin
          pub = Publication.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          error!({ "error" => "No such publication", "detail" => "You've requested a non-existant publication." }, 404)
        end
      if pub.deleted 
        error!("Gone - old resource probably deleted.", 410)
      end
      pub.pub_hash
    end

    # MARK A RECORD AS DELETED
    delete ':id' do
      error!('Unauthorized', 401) unless env['HTTP_CAPKEY'] == '***REMOVED***'
      pub = Publication.find(params[:id])
      pub.deleted = true
      pub.save
    end

  end
 

end

