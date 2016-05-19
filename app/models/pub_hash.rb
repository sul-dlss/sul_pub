require 'citeproc'

class PubHash
  def initialize(hash)
    @hash = hash
  end

  def citeproc_authors
    @citeproc_authors ||= parse_authors[:authors]
  end

  def citeproc_editors
    @citeproc_editors ||= parse_authors[:editors]
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
    CiteProc.process(to_citation_data, style: chicago_csl_file, format: 'html')
  end

  def to_mla_citation
    mla_csl_file = Rails.root.join('app', 'data', 'mla.csl')
    CiteProc.process(to_citation_data, style: mla_csl_file, format: 'html')
  end

  def to_apa_citation
    apa_csl_file = Rails.root.join('app', 'data', 'apa.csl')
    CiteProc.process(to_citation_data, style: apa_csl_file, format: 'html')
  end

  def to_citation_data
    @citation_data ||= begin

      cit_data_hash = {
        'id' => 'sulpub',
        'type' => pub_hash[:type],
        'author' => citeproc_authors,
        'title' => pub_hash[:title]
      }

      # Access to abstracts may be restricted by license agreements with data providers.
      # cit_data_hash["abstract"] = pub_hash[:abstract] unless pub_hash[:abstract].blank?

      cit_data_hash['chapter-number'] = pub_hash[:articlenumber] unless pub_hash[:articlenumber].blank?
      cit_data_hash['page'] = pub_hash[:pages] unless pub_hash[:pages].blank?
      cit_data_hash['publisher'] = pub_hash[:publisher] unless pub_hash[:publisher].blank?

      # Add series information if it exists.
      if pub_hash.key?(:series)
        unless pub_hash[:series][:title].blank?
          cit_data_hash['type'] = 'book'
          cit_data_hash['collection-title'] = pub_hash[:series][:title]
        end
        cit_data_hash['volume'] = pub_hash[:series][:volume] unless pub_hash[:series][:volume].blank?
        cit_data_hash['number'] = pub_hash[:series][:number] unless pub_hash[:series][:number].blank?
        cit_data_hash['issued'] = { 'date-parts' => [[pub_hash[:series][:year]]] } unless pub_hash[:series][:year].blank?
      end

      # Add journal information if it exists.
      if pub_hash.key?(:journal)
        unless pub_hash[:journal][:name].blank?
          cit_data_hash['type'] = 'article-journal'
          cit_data_hash['container-title'] = pub_hash[:journal][:name]
        end
        cit_data_hash['volume'] = pub_hash[:journal][:volume] unless pub_hash[:journal][:volume].blank?
        cit_data_hash['issue'] = pub_hash[:journal][:issue] unless pub_hash[:journal][:issue].blank?
        cit_data_hash['issued'] = { 'date-parts' => [[pub_hash[:journal][:year]]] } unless pub_hash[:journal][:year].blank?
        cit_data_hash['number'] = pub_hash[:supplement] unless pub_hash[:supplement].blank?
      end

      # Add any conference information, if it exists in a conference object;
      # this overrides the sciencewire fields above if both exist, which they shouldn't.
      if pub_hash.key?(:conference)
        cit_data_hash['event'] = pub_hash[:conference][:name] unless pub_hash[:conference][:name].blank?
        cit_data_hash['event-date'] = pub_hash[:conference][:startdate] unless pub_hash[:conference][:startdate].blank?
        # override the startdate if there is a year:
        cit_data_hash['event-date'] = { 'date-parts' => [[pub_hash[:conference][:year]]] } unless pub_hash[:conference][:year].blank?
        cit_data_hash['number'] = pub_hash[:conference][:number] unless pub_hash[:conference][:number].blank?
        if !pub_hash[:conference][:city].blank? || !pub_hash[:conference][:statecountry].blank?
          cit_data_hash['event-place'] = pub_hash[:conference][:city]
          cit_data_hash['event-place'] << ',' unless pub_hash[:conference][:city].blank? || pub_hash[:conference][:statecountry].blank?
          cit_data_hash['event-place'] << pub_hash[:conference][:statecountry] unless pub_hash[:conference][:statecountry].blank?
        elsif !pub_hash[:conference][:location].blank?
          cit_data_hash['event-place'] = pub_hash[:conference][:location]
        end
        # cit_data_hash["DOI"] = pub_hash[:conference][:DOI] unless pub_hash[:conference][:DOI].blank?
      end

      # Use a year at the top level if it exists, i.e, override any year we'd gotten above from journal or series.
      cit_data_hash['issued']  = { 'date-parts' => [[pub_hash[:year]]] } unless pub_hash[:year].blank?
      # Add book title if it exists, which indicates this pub is a chapter in the book.
      unless pub_hash[:booktitle].blank?
        cit_data_hash['type'] = 'book'
        cit_data_hash['container-title'] = pub_hash[:booktitle]
      end

      if cit_data_hash['type'] && cit_data_hash['type'].casecmp('book') == 0 && !citeproc_editors.empty?
        cit_data_hash['editor'] = citeproc_editors
      end

      ##
      # For a CAP type "technicalReport" just use a "report"
      cit_data_hash['type'] = 'report' if pub_hash[:type] == 'technicalReport'

      ##
      # Mapping custom fields from the CAP system.
      cit_data_hash['URL'] = pub_hash[:publicationUrl] if pub_hash[:publicationUrl].present?
      cit_data_hash['publisher-place'] = pub_hash[:publicationSource] if pub_hash[:publicationSource].present?

      [cit_data_hash]
    end
  end
end

private

  def parse_authors
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
      last_name = ''
      rest_of_name = ''

      # use parsed name parts if available
      unless author[:lastname].blank?
        last_name = author[:lastname]
        unless author[:firstname].blank?
          if author[:firstname].length == 1
            rest_of_name << ' ' << author[:firstname] << '.'
          else
            rest_of_name << ' ' << author[:firstname]
          end
        end

        unless author[:middlename].blank?
          if author[:middlename].length == 1
            rest_of_name << ' ' << author[:middlename] << '.'
          else
            rest_of_name << ' ' << author[:middlename]
          end
        end
      end

      # use name otherwise and if available
      if last_name.blank? && !author[:name].blank?
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
        if author[:role] && author[:role].casecmp('editor') == 0
          editors_for_citeproc << { 'family' => last_name, 'given' => rest_of_name }
        else
          authors_for_citeproc << { 'family' => last_name, 'given' => rest_of_name }
        end
      end
    end
    {
      authors: authors_for_citeproc,
      editors: editors_for_citeproc
    }
  end
