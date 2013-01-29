module SulBib

  class API < Grape::API
    
  version 'v1', :using => :header, :vendor => 'sul'

  format :json

      get do
        population = params[:population] 
        changedSince = params[:changedSince]
        population ||= "cap"
        changedSince ||= "1800-01-01"

        startDate = DateTime.parse(changedSince)
        matching_records = Publication.where("updated_at > ?", changedSince)

        '{
    "metadata": {
        "_created": "' +   Time.now.iso8601  + '",  
        "description": "sciencewire sample, as BibJSON, for cap experimentation", 
        "format": "BibJSON",  
        "license": "some licence", 
        "population": "' + population + '",
        "changedSince": "' + changedSince + '",
        "query": "http://publication?population=cap", 
        "records": ' + matching_records.count.to_s + '
    }, 
    "records": [' + matching_records.each.map { |publication| publication.json }.join(",") + ']}'
        
      end

      get ':id' do
        Publication.find(params[:id]).json
      end
    
  end 
    
end