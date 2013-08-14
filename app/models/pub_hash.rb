require 'citeproc'

class PubHash
  def initialize hash
    @hash = hash
  end

  def pub_hash
    @hash
  end

  def to_chicago_citation
    authors = pub_hash[:author] || [] 
    if pub_hash[:etal] || authors.length > 5
      chicago_csl_file = Rails.root.join('app', 'data', 'chicago-author-date_et_al.csl')
    else
      chicago_csl_file = Rails.root.join('app', 'data', 'chicago-author-date.csl')
    end
    CiteProc.process(to_citation_data, :style => chicago_csl_file, :format => 'html')
  end

  def to_mla_citation
    mla_csl_file = Rails.root.join('app', 'data', 'mla.csl')
    CiteProc.process(to_citation_data, :style => mla_csl_file, :format => 'html')
  end

  def to_apa_citation
    apa_csl_file = Rails.root.join('app', 'data', 'apa.csl')
    CiteProc.process(to_citation_data, :style => apa_csl_file, :format => 'html')
  end

  def to_citation_data
    @citation_data ||= begin
      authors_for_citeproc = []
      editors_for_citeproc = []

      authors = pub_hash[:author] || []

      if authors.length > 5
        # we pass the first five  authorsand the very last author because some
        # formats add the very last name when using et-al. the CSL should drop the sixth name if unused.
        # We could in fact pass all the author names to the CSL processor and let it
        # just take the first five, but that seemed to crash the processor for publications
        # with a lot of authors (e.g, 2000 authors)
        authors = authors[0..4]
        authors << pub_hash[:author].last
     #   authors << {:name=>"et al."}
     # elsif pub_hash[:etal]
     #   authors = pub_hash[:author].collect {|a| a}
     #   authors << {:name=>"et al."}
      end

      authors.each do |author|
        last_name = ""
        rest_of_name = ""

        # use parsed name parts if available
        unless author[:lastname].blank?
          last_name = author[:lastname]
          unless author[:firstname].blank?
            if author[:firstname].length == 1
              rest_of_name << ' ' << author[:firstname] << '.'
            else
              rest_of_name << ' ' <<  author[:firstname]
            end
          end

          unless author[:middlename].blank?
            if author[:middlename].length == 1
              rest_of_name << ' ' << author[:middlename] << '.'
            else
              rest_of_name << ' ' <<  author[:middlename]
            end
          end
        end

        # use name otherwise and if available
        if last_name.blank? && ! author[:name].blank?
          author[:name].split(',').each_with_index do |name_part, index|
            if index == 0
              last_name = name_part
            elsif name_part.length == 1
              # the name part is only one character so an initial
              rest_of_name << ' ' << name_part << '.'
            elsif name_part.length > 1
              rest_of_name << ' ' << name_part
            end
          end
        end

       unless last_name.blank?
        if author[:role] && author[:role].casecmp("editor") == 0
          editors_for_citeproc << {"family" => last_name, "given" => rest_of_name} 
        else 
          authors_for_citeproc << {"family" => last_name, "given" => rest_of_name}
        end 
      end
      end


      cit_data_hash = {"id" => "sulpub",
                   "type"=>pub_hash[:type],
                   "author"=>authors_for_citeproc,
                   "title"=>pub_hash[:title]

                   }

    #cit_data_hash["abstract"] = pub_hash[:abstract] unless pub_hash[:abstract].blank?

    unless authors_for_citeproc.empty? then cit_data_hash["author"] = authors_for_citeproc end

    unless pub_hash[:articlenumber].blank? then cit_data_hash["chapter-number"] = pub_hash[:articlenumber] end
    unless pub_hash[:pages].blank? then cit_data_hash["page"] = pub_hash[:pages] end
    unless pub_hash[:publisher].blank? then cit_data_hash["publisher"] = pub_hash[:publisher] end

  # add series information if it exists
  if pub_hash.has_key?(:series)
    unless pub_hash[:series][:title].blank? then 
      cit_data_hash[:type] = 'book'
      cit_data_hash["collection-title"] = pub_hash[:series][:title] 
    end
    unless pub_hash[:series][:volume].blank? then cit_data_hash["volume"] = pub_hash[:series][:volume] end
    unless pub_hash[:series][:number].blank? then cit_data_hash["number"] = pub_hash[:series][:number] end
    unless pub_hash[:series][:year].blank? then cit_data_hash["issued"]  = {"date-parts"=>[[pub_hash[:series][:year]]]} end
    
 end
 # add journal information if it exists
 if pub_hash.has_key?(:journal)
    unless pub_hash[:journal][:name].blank? then 
      cit_data_hash[:type] = 'article'
      cit_data_hash["container-title"] = pub_hash[:journal][:name] 
    end
    unless pub_hash[:journal][:volume].blank? then cit_data_hash["volume"] = pub_hash[:journal][:volume] end
    unless pub_hash[:journal][:issue].blank? then cit_data_hash["issue"] = pub_hash[:journal][:issue] end
    unless pub_hash[:journal][:year].blank? then cit_data_hash["issued"]  = {"date-parts"=>[[pub_hash[:journal][:year]]]} end
    unless pub_hash[:supplement].blank? then cit_data_hash[:number] = pub_hash[:supplement] end
  end
   
   # add any conference information, if it exists in a conference object
  # this overrides the sciencewire fields above if both exist, which they shouldn't
  if pub_hash.has_key?(:conference)
      unless pub_hash[:conference][:name].blank? then cit_data_hash["event"] = pub_hash[:conference][:name] end
      unless pub_hash[:conference][:startdate].blank? then cit_data_hash["event-date"] = pub_hash[:conference][:startdate] end
        #override the startdate if there is a year:
      unless pub_hash[:conference][:year].blank? then cit_data_hash["event-date"] = {"date-parts"=>[[pub_hash[:conference][:year]]]} end
      unless pub_hash[:conference][:number].blank? then cit_data_hash["number"] = pub_hash[:conference][:number] end
      if ! pub_hash[:conference][:city].blank? || ! pub_hash[:conference][:statecountry].blank?
        cit_data_hash["event-place"] = pub_hash[:conference][:city]
        if ! pub_hash[:conference][:city].blank? && ! pub_hash[:conference][:statecountry].blank? then cit_data_hash["event-place"] << ',' end
        unless pub_hash[:conference][:statecountry].blank? then cit_data_hash["event-place"] << pub_hash[:conference][:statecountry] end
      elsif ! pub_hash[:conference][:location].blank? 
        cit_data_hash["event-place"] = pub_hash[:conference][:location]
      end
     # unless pub_hash[:conference][:DOI].blank? then cit_data_hash["DOI"] = pub_hash[:conference][:DOI] end
  end

      # use a year at the top level if it exists, i.e, override any year we'd gotten above from journal or series
  unless pub_hash[:year].blank? then cit_data_hash["issued"]  = {"date-parts"=>[[pub_hash[:year]]]} end
  # add book title if it exists, which indicates this pub is a chapter in the book
  unless pub_hash[:booktitle].blank? then 
    cit_data_hash[:type] = 'book'
    cit_data_hash["container-title"] = pub_hash[:booktitle] 
  end

  if cit_data_hash[:type].casecmp("book") == 0 && ! editors_for_citeproc.empty?
    cit_data_hash["editor"] = editors_for_citeproc 
  end




      cit_data_array = [cit_data_hash]
    end
  end
end