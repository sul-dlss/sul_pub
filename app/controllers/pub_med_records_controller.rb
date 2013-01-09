class PubMedRecordsController < ApplicationController
  

  def index
  end

  def search
    queryTerm = params[:query] 
    @results = PubmedSearch.search queryTerm

	# @resultCount = results.count
	# @meshTerms = results.exploded_mesh_terms

		#=> #<Set: {"mice"}>

    # @totalResults = Publication.find_in_pubmed(queryTerm)
    #respond_to do | client_wants |
    #	client_wants.html { redirect_to }
    #	client_wants.xml { render :xml => results.to_xml }
    #end

  end

  def show
    pubMedId = params[:pubMedId]
    Bio::NCBI.default_email = "jc@openskysolutions.ca"
    pub =  Bio::PubMed.efetch("14693807", 'retmode' => 'xml')
    xml = Nokogiri::XML(pub)
    @record = xml.to_s
  end

  def populate
    Bio::NCBI.default_email = "jc@openskysolutions.ca"
    @pubMedIds = Bio::PubMed.esearch("(genome AND analysis) OR bioinformatics")
    
#@pubMedIds.each do |x|
 # p x
#end
@pubMedRecords = Bio::PubMed.efetch(@pubMedIds, 'retmode' => 'xml')

    #Bio::PubMed.efetch(["23173205", "23173097"], 'retmode' => 'xml').each do |entry|
      #medline = Bio::MEDLINE.new(entry)
      #reference = medline.reference
      #puts reference.bibtex
    @xml = Nokogiri::XML(@pubMedRecords).to_s
    #  @pubMedRecords << Nokogiri::XML(entry).to_s
   # end

    @result = @pubMedIds.join;

     # flash[:notice] = "Populated!"
      #redirect_to pub_med_records_index_path




    

  end

end
