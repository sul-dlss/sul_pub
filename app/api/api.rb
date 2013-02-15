module SulBib

  
class BibTexParser
    def self.call(object, env) 
        { :value => object.to_s }
    end
end

  class API_samples < Grape::API
    version 'v1', :using => :header, :vendor => 'sul', :format => :json
    format :json
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

  class API < Grape::API
    
  version 'v1', :using => :header, :vendor => 'sul'

  format :json

      get do
    
       # error!('Unauthorized', 401) unless env['HTTP_STANFORDKEY'] == 'thetree'

        population = params[:population] 
        changedSince = params[:changedSince]
        population ||= "cap"
        changedSince ||= "1800-01-01"

        startDate = DateTime.parse(changedSince)
        #matching_records = Publication.where("updated_at > ?", changedSince).limit(20)
        
        matching_records = []
        # POSSIBLY ADD ANOTHER CALL TO RETURN A LIST OF ALL AUTHORS IN A GIVEN POPULATION.
        # matching_people = Person.all(:include => :population_memberships, :conditions => "population_memberships.population_name = 'cap'")
         #puts matching_people
        # puts  "count" + matching_people.count.to_s
        #  matching_people.[0..2] { |person|  matching_records << person.publications.where("publications.updated_at > ?", changedSince)}
        # puts matching_records.to_s
        contributions_for_population = Contribution.all(:include => :population_membership, :conditions => "population_memberships.population_name = 'cap'")
        contributions_for_population.each {|contr| matching_records << contr.publication.json }
        '{
        "metadata": {
        "_created": "' +   Time.now.iso8601  + '",  
        "description": "Sciencewire sample, as BibJSON, for CAP experimentation", 
        "format": "BibJSON",  
        "license": "some licence", 
        "population": "' + population + '",
        "query": "' + env["ORIGINAL_FULLPATH"] + '", 
        "records": ' + matching_records.count.to_s + '}, 
        "records": [' + matching_records.join(",") + ']}'
      end

      get ':id' do
        #env.each { |val| puts val}
        Publication.find(params[:id]).json
      end

      delete ':id' do
        #env.each { |val| puts val}
        pub = Publication.find(params[:id])
        pub.deleted = true
        pub.save
      end

      #content_type :json, "application/json"
      #content_type :bibtex, "text/bibliography"
      #parser :bibtex, BibTexParser

      post do 
        params[:value]
      end

      put do
        params[:value]
      end


  end 


end

