class PubMedRecord < ActiveRecord::Base

	def self.find_in_pubmed
		results = PubmedSearch.search "Mus musculus"

		results.pmids.length
		#=> 100000

		results.count
		#=> 951134

		results.exploded_mesh_terms
		#=> #<Set: {"mice"}>
	end

	def self.get_record_in_pubmed

	end
	
end