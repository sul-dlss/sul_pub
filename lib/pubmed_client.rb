class PubmedClient

	def fetch_records_for_pmid_list(pmid_list)
		pmidValuesForPost = pmid_list.collect { |pmid| "&id=#{pmid}"}.join
		http = Net::HTTP.new("eutils.ncbi.nlm.nih.gov")	
		request = Net::HTTP::Post.new("/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml")
		request.body = pmidValuesForPost
		http.start
		the_incoming_xml = http.request(request).body
		http.finish
		the_incoming_xml
	end
		
end