module CapPubsIngest
	
	#"PUBLICATION_ID","FACULTY_ID","LAST_MODIFIED_DATE","LAST_MODIFIED_USER_ID","STATUS","HIGHLIGHT_IND"
	#20069,4132,26-SEP-04 02.58.58.000000000 PM,21,"new",0
	
	def ingestCapProfiles
		# this is probably from their API, rather than from a csv?
	end

	def getPubMedForAllIds
		filename = Rails.root.join('app', 'data', 'CAP_author_pubs_sample.csv')
		CSV.foreach(filename, :headers => true) do |row|

			line = row.parse_csv
			contribution = {
				:profile_id => line[1]
				:publication_id = line[0]
				:status = line[4]
				:highlight = line[5]
			}
			contribution_mappings << contribution
			pmidList << line[0]
			if pmidList.count == 200
				pmids
				sw_records = get_sciencewirecords(pmids)
				pubmed_records = get_pubmed_records(pmids)
				create_new_sul_records(sw_records, pubmed_records, contribution_mappings)

			
	end

	def addMESHToSWRecords

	end

	def ingestCapHandEnteredPubs
		# this is from a csv
	end

	def ingestCapContributions
		filename = Rails.root.join('app', 'data', 'CAP_author_pubs_sample.csv')
		CSV.foreach(filename, :headers => true) do |row|

			make call here to get the SW record based on pmid

			contribution = row.parse_csv
			profile_id = contribution[1]
			publication_id = contribution[0]
			status = contribution[4]
			highlight = contribution[5]

			#setup a person record for the profile id (maybe getting full profile info from somewhere?)

  			Person.create!  (or just check that the id already exists.
  			PersonIdentifier  (add the cap profile id) 			

			#get the pubmed id then get the sciencewire record, then create pub, then associate the two:
  			
  			Source_Record.create
  			Publication.create!
			Publication_Source_Record.create

			# then associate the pub with the person, i.e., create the contribution

			Contribution.create!
  			
		end
	end
end

# 1. import profiles - create a Person record with values from profile record.
# 2. import contributions (person/pubmed pairs)
# 3. import hand-entered Publication_Source_Record

