module SulBib

  class API < Grape::API
    
  version 'v1', :using => :header, :vendor => 'sul'

  format :json


        

      get do

        '{
    "metadata": {
        "_created": "20121121190112",  
        "description": "sample of bibjson output taken from bisoup.net for cap experimentation", 
        "format": "bibtex",  
        "license": "http://www.opendefinition.org/licenses/cc-zero", 
        "query": "http://publication?pop=cap", 
        "records": 20
    }, 
    "records": [' + Publication.all.each.map { |publication| publication.json }.join(",") + ']}'
        #Hash.from_xml('<some><child>hhjones</child></some>').to_json
        #eventually replace this with a call possibly to solr.
        #The json/xml has to have the contribution info, and dedupe info.

      end
    
  end 
    
end