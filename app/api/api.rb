module SulBib

  

  class BibTexParser
    def self.call(object, env)
      { :value => object.to_s }
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

    version 'v1', :using => :header, :vendor => 'sul'
    format :json
    rescue_from :all, :backtrace => true
    

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
       # query_hash[:last_name] = last_name unless last_name.empty? 
        #query_hash[:first_name] = first_name unless first_name.empty?
        #query_hash[:middle_name] = middle_name unless middle_name.empty?
        query_hash[:human_readable_title] = title unless title.blank?
        query_hash[:year] = year unless year.blank?
        Publication.where(query_hash).each { |pub| local_records << pub.json }
      end

      all_matching_records = sw_json_records.concat(local_records)
      wrap_as_bibjson_collection("Search results from requested sources: " + source, env["ORIGINAL_FULLPATH"], all_matching_records)
    
    end

    get do
      # error!('Unauthorized', 401) unless env['HTTP_STANFORDKEY'] == 'thetree'
      matching_records = []

      population = params[:population] || "cap"
      changedSince = params[:changedSince] || "1800-01-01"
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
      #  Contribution.find_each(
       #   :include => :population_membership,
        #  :conditions => "population_memberships.population_name = '" + population + "' AND contributions.updated_at > '" + DateTime.parse(changedSince).to_s + "'"
        #) do
        #  |contr| matching_records << contr.publication.json
       # end
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


    #content_type :json, "application/json"
    #content_type :bibtex, "text/bibliography"
    #parser :bibtex, BibTexParser



    post do
      params[:value]
    end

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
