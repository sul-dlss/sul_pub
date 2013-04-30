module SulSolr

  def index_manual_contributions_in_solr

Publication.find_each(:include => :source_record, :conditions => "source_record.source_name = 'user' ") do | publication |
  
    pub_hash = JSON.parse(publication.json)
       
=begin        
        
        I NEED A TEST CASE HERE, WITH A PUBLICATION FACTORY THAT WILL GENERATE A PUBLICATION WITH JSON WITH A
        FULLY POPULATED AUTHOR LIST, INCLUDING MIDDLENAME, ETC.  

          - create the factory, then write the rspec test to GET the publication, and one to test the solr indexing
=end
        pub_hash[author].each do |author| 
            last_name = ""
            rest_of_name = ""
            author.split(',').each_with_index do |name_part, index|
                if index == 0
                  last_name = name_part
                elsif name_part.length == 1
                  rest_of_name << ' ' << name_part << '.'
                elsif name_part.length > 1
                  rest_of_name << ' ' << name_part
                end
            end
     
        solr_doc = {
          id: publication.id, 
          title: publication.human_readable_title,
          bibjson: publication.json,
          year: publication.year

        }
        
            
        end
         
        solr = RSolr.connect :url => 'http://localhost:8080/solr'
        solr.add solr_doc, :add_attributes => {:commitWithin => 10}
      end
        #solr.commit
  end
end