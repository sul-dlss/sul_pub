require 'citeproc'

class PubHash
  attr_reader :pub_hash

  def initialize(hash)
    @pub_hash = hash
  end

  # @param csl_citation_data [Array<Hash>] an array of CSL citation documents
  # @param csl_style_file [String] a CSL citation style file path
  # @return citation [String] a bibliographic citation
  def generate_csl_citation(csl_citation_data, csl_style_file)
    CiteProc.process(csl_citation_data, style: csl_style_file, format: 'html')
  end

  def to_chicago_citation
    @chicago_csl_file ||= begin
      style_name = 'chicago-author-date'
      # sul-pub has a custom modification that can be used for many authors
      authors = pub_hash[:author] || []
      style_name += '_et_al' if pub_hash[:etal].present? || authors.count > 5
      Rails.root.join('app', 'data', style_name + '.csl')
    end
    generate_csl_citation([csl_doc], @chicago_csl_file)
  end

  def to_mla_citation
    @mla_csl_file ||= Rails.root.join('app', 'data', 'mla.csl')
    generate_csl_citation([csl_doc], @mla_csl_file)
  end

  def to_apa_citation
    @apa_csl_file ||= Rails.root.join('app', 'data', 'apa.csl')
    generate_csl_citation([csl_doc], @apa_csl_file)
  end

  def csl_doc
    @csl_doc ||= begin

      if pub_hash[:provenance] =~ /cap/i
        # This is a CAP manual submission
        case pub_hash[:type]
        when 'workingPaper', 'technicalReport'
          # Map a CAP 'workingPaper' or 'technicalReport' to a CSL 'report'
          return create_csl_report
        end
        ##
        # Other doc-types include:
        # - article
        # - book
        # - inbook
        # - inproceedings
      end

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
      # For a CAP type "caseStudy" just use a "book"
      cit_data_hash['type'] = 'book' if pub_hash[:type] == 'caseStudy'

      ##
      # Mapping custom fields from the CAP system.
      cit_data_hash['URL'] = pub_hash[:publicationUrl] if pub_hash[:publicationUrl].present?
      cit_data_hash['publisher-place'] = pub_hash[:publicationSource] if pub_hash[:publicationSource].present?

      cit_data_hash
    end
  end
end

private

  def citeproc_authors
    @citeproc_authors ||= parse_authors[:authors]
  end

  def citeproc_editors
    @citeproc_editors ||= parse_authors[:editors]
  end

  # @param [Array<Hash>] CAP authors array of hash data
  # @return [Array<Hash>] CSL authors array of hash data
  def cap_authors_to_csl(cap_authors, role = 'author')
    cap_authors.map do |author|
      author = author.symbolize_keys
      next unless author[:role] == role
      ln = author[:lastname].to_s.strip
      fn = author[:firstname].to_s.strip
      mn = author[:middlename].to_s.strip
      given = "#{fn} #{mn}".strip
      { 'family' => ln, 'given' => given }
    end.compact
  end

  def create_csl_report
    # Report – A document containing the findings of an individual or group.
    # Can include a technical paper, publication, issue brief, or working paper.
    #
    # The Zotero and Mendeley mappings to a CSL report guided this implementation, see
    # http://aurimasv.github.io/z2csl/typeMap.xml#map-report
    # http://support.mendeley.com/customer/portal/articles/364144-csl-type-mapping
    csl_report = {}
    csl_report['id'] = 'sulpub'
    csl_report['type'] = 'report'
    authors = cap_authors_to_csl(pub_hash[:author])
    csl_report['author'] = authors unless authors.empty?
    editors = cap_authors_to_csl(pub_hash[:author], 'editor')
    csl_report['editor'] = editors unless editors.empty?
    csl_report['title'] = pub_hash[:title] if pub_hash[:title].present?
    csl_report['abstract'] = pub_hash[:abstract] if pub_hash[:abstract].present?
    csl_report['publisher'] = pub_hash[:publisher] if pub_hash[:publisher].present?
    csl_report['publisher-place'] = pub_hash[:publicationSource] if pub_hash[:publicationSource].present?
    # Date Accessed -> accessed
    if pub_hash[:year].present?
      csl_report['issued'] = {
        'date-parts' => [[ pub_hash[:year] ]]
      }
    end
    url = pub_hash[:publicationUrl]
    csl_report['URL'] = url if url.present?
    series = pub_hash[:series]
    if series.present?
      csl_report['collection-title'] = series[:title] if series[:title].present?
      csl_report['volume'] = series[:volume] if series[:volume].present?
      csl_report['number'] = series[:number] if series[:number].present?
    end
    csl_report['page'] = pub_hash[:pages] if pub_hash[:pages].present?
    csl_report
  end

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
