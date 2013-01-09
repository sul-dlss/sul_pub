class PublicationsController < ApplicationController
  def new
  end

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

end
