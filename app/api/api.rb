module SulBib

#validator for year

class YearCheck < Grape::Validations::Validator
  def validate_param!(attr_name, params)
    unless (1000..2100).include?(params[attr_name])
      throw :error, :status => 400, :message => "#{attr_name} must be four digits long and fall between 1000 and 2100"
    end
  end
end

#bibtex and bibjson parsers to parse incoming POSTs and PUTs
  module BibTexParser
    def self.call(object, env) 
        result = []
        bibtex_records =  
        bibtex_records.each do |record|   
          result << {title: record.title, 
                      year: record.year, 
                      publisher: record.publisher, 
                      authors: record.author}      
        end
        {:bib_list => result}
    end
  end

 module BibJSONParser
    def self.call(object, env) 
      {:bib_list => JSON.parse(object)}
    end     
  end

  class API_samples < Grape::API
    version 'v1', :using => :header, :vendor => 'sul', :format => :json
    format :json
    rescue_from :all, :backtrace => true
    
    get(:get_pub_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'get_pub_out.json')) }
    get(:get_pubs_out) { IO.read(Rails.root.join('app', 'data', 'api_samples', 'get_pubs_out.json')) }
    get(:get_source_lookup_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'get_source_lookup_out.json')) }
    get(:post_pub_in) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'post_pub_in.json'))}
    get(:post_pub_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'post_pub_out.json'))}
    get(:post_pubs_in) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'post_pubs_in.json'))}
    get(:post_pubs_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'post_pubs_out.json'))}
    get(:put_pub_in) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'put_pub_in.json'))}
    get(:put_pub_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'put_pub_out.json'))}
    get(:delete_pub_out) {IO.read(Rails.root.join('app', 'data', 'api_samples', 'delete_pub_out.json'))}
  end

  class API_people < Grape::API
    version 'v1', :using => :header, :vendor => 'sul', :format => :json
    format :json
    get 'authors' do
      Author.all(:include => :population_memberships, :conditions => "population_memberships.population_name = 'cap'")
    end
  end

  class API < Grape::API

    version 'v1', :using => :header, :vendor => 'sul', :cascade => false
    format :json
    rescue_from :all, :backtrace => true
    
    #rescue_from :all do |e|
    #    rack_response({ :message => "rescued from #{e.class.name}" })
    #end

helpers do
  def wrap_as_bibjson_collection(description, query, records)
    '{
        "metadata": {
        "_created": "' +   Time.now.iso8601  + '",  
        "description": "' + description + '", 
        "format": "BibJSON",  
        "license": "some licence", 
        "query": "' + query + '", 
        "records": ' + records.count.to_s + '}, 
        "records": [' + records.join(",") + ']}'
  end
  include SulPub
end


params do
  optional :year, type: Integer, :year_check => true, desc: "Four digit year."
  requires :title
  optional :source
end

get :sourcelookup do
      sw_json_records = []
      local_records = []

      # set source to all sources if param value is blank     
      source = params[:source] || 'SW+MAN'
      last_name = params[:lastname]
      first_name = params[:firstname]
      middle_name = params[:middlename]
      title = params[:title]
      year = params[:year]

      sources = source.split('+')

      if source.include?("SW")
        sw_json_records = query_sciencewire_for_publication(first_name, last_name, middle_name, title, year)
      end

      if source.include?("MAN")
        query_hash = {}
        #query_hash[:last_name] = last_name unless last_name.empty? 
        #query_hash[:first_name] = first_name unless first_name.empty?
        #query_hash[:middle_name] = middle_name unless middle_name.empty?
        query_hash[:human_readable_title] = title unless title.blank?
        query_hash[:year] = year unless year.blank?
        query_hash[:is_active] = true
        query_hash[:is_local_only] = true  

        SourceRecord.where(query_hash).each { |source_record| local_records << source_record.publication.json }
      end

      all_matching_records = sw_json_records.concat(local_records)
      wrap_as_bibjson_collection("Search results from requested sources: " + source, env["ORIGINAL_FULLPATH"], all_matching_records)
    
    end

    get do
      # error!('Unauthorized', 401) unless env['HTTP_STANFORDKEY'] == 'thetree'
      matching_records = []

      population = params[:population] || "cap"
      changedSince = params[:changedSince] || "1000-01-01"
      capProfileId = params[:capProfileId]

      population.downcase!

      if capProfileId.blank?
        description = "Records for population '" + population + "' that have changed since " + changedSince
        Publication.find_each(
          :include => :population_membership,
          :conditions => "population_memberships.population_name = '" + population + "' AND publications.updated_at > '" + DateTime.parse(changedSince).to_s + "'"      
          ) do
            | publication | matching_records << publication.json
        end
      else
        author = Author.where(cap_profile_id: capProfileId).first
        if author.nil?
          description = "No results - user identifier doesn't exist in SUL system."
        else
          description = "All known publications for CAP profile id " + capProfileId
          matching_records = author.contributions.collect { |contr| contr.publication.json }
        end
      end
      wrap_as_bibjson_collection(description, env["ORIGINAL_FULLPATH"].to_s, matching_records)
    end

    content_type :json, "application/json"
    content_type :bibtex, "text/bibliography"
    parser :bibtex, BibTexParser
    parser :json, BibJSONParser
    post do
          record_list = params[:bib_list]
          is_local_only = true
          is_active = true
          original_source_id = nil
          record_list.each do |pub_hash|
            pub_hash[:provenance] = 'cap'
            year = pub_hash[:year]
            title = pub_hash[:title]
            pub = Publication.create(active: true, human_readable_title: title, year: year)
            save_source_record(pub, pub_hash.to_hash.to_s, "man", pub_hash[:title], pub_hash[:year], original_source_id, is_local_only, is_active)
            sul_pub_id = pub.id.to_s
            pub_hash[:sulpubid] = sul_pub_id
            pub_hash[:identifier] << {:type => 'SULPubId', :id => sul_pub_id, :url => 'http://sulcap.stanford.edu/publications/' + sul_pub_id}
            pub.save   # to reset last updated value
            pub_hash[:last_updated] = pub.updated_at
            #"contributions":[{"sul_author_id":1263,"cap_profile_id":5956,"status":"denied"}]
            pub_hash[:contributions].each do |contrib|
                cap_profile_id = contrib[:cap_profile_id]
                sul_author_id = Author.where(cap_profile_id: cap_profile_id).first.id
                contrib_status = contrib[:status]
                add_contribution_to_db(sul_pub_id, sul_author_id, cap_profile_id, contrib_status)
            end
            add_all_known_contributions_to_pub_hash(pub, pub_hash)

            add_identifiers_to_db(pub_hash[:identifier], pub)
            add_all_known_identifiers_to_pub_hash(pub_hash, pub)

            add_formatted_citations(pub_hash)

            pub.json = generate_json_for_pub(pub_hash)
            pub.xml = generate_xml_for_pub(pub_hash)
            pub.save
            pub.json
          end
        
    
      #puts "submitted data: " + env['api.request.body'].to_s
      #puts "parse data: " + BibTeX.parse(env['api.request.input'])[:pickaxe].to_s
      #puts params[:value][:pickaxe].to_s

    end

    content_type :json, "application/json"
    content_type :bibtex, "text/bibliography"
    parser :bibtex, BibTexParser
    put ':id' do
      params[:value]
    end

    get ':id' do
      Publication.find(params[:id]).json
    end

    delete ':id' do
      pub = Publication.find(params[:id])
      pub.deleted = true
      pub.save
    end

  end
end
