module Csl

  class Mapper
    attr_reader :pub_hash

    # @param pub_hash [Hash] a Publication.pub_hash
    def initialize(pub_hash)
      @pub_hash = pub_hash
    end

    def csl_doc
      @csl_doc ||= begin

        ##
        # Parse authors for various provenance data:
        # - batch
        # - cap
        # - pubmed
        # - sciencewire
        provenance = pub_hash[:provenance].to_s.downcase
        authors = pub_hash[:author] || []
        case provenance
        when 'batch'
          # This is from BibtexIngester.convert_bibtex_record_to_pub_hash
          @citeproc_authors ||= Csl::BibtexMapper.authors_to_csl(authors)
          @citeproc_editors ||= [] # there are no editors
        when 'cap'
          # This is a CAP manual submission
          @citeproc_authors ||= Csl::CapMapper.authors_to_csl(authors)
          @citeproc_editors ||= Csl::CapMapper.editors_to_csl(authors)
        when 'pubmed'
          # This is a PubMed publication and the author is created in
          # PubmedSourceRecord.convert_pubmed_publication_doc_to_hash
          @citeproc_authors ||= Csl::PubmedMapper.authors_to_csl(authors)
          @citeproc_editors ||= [] # there are no editors
        when 'sciencewire'
          # This is a ScienceWire publication and the author is created in
          # SciencewireSourceRecord.convert_sw_publication_doc_to_hash
          @citeproc_authors ||= Csl::SciencewireMapper.authors_to_csl(authors)
          @citeproc_editors ||= [] # there are no editors
        else
          citeproc_authors # calls parse_authors
          citeproc_editors # calls parse_authors
        end

        if provenance == 'cap'
          case pub_hash[:type].to_s.downcase
          when 'workingpaper', 'technicalreport'
            # Map a CAP 'workingPaper' or 'technicalReport' to a CSL 'report'
            return Csl::CapMapper.create_csl_report(pub_hash, citeproc_authors, citeproc_editors)
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
          'type' => pub_hash[:type].to_s.downcase,
          'author' => citeproc_authors,
          'title' => pub_hash[:title]
        }

        # Access to abstracts may be restricted by license agreements with data providers.
        # cit_data_hash["abstract"] = pub_hash[:abstract] if pub_hash[:abstract].present?

        cit_data_hash['chapter-number'] = pub_hash[:articlenumber] if pub_hash[:articlenumber].present?
        cit_data_hash['page'] = pub_hash[:pages] if pub_hash[:pages].present?
        cit_data_hash['publisher'] = pub_hash[:publisher] if pub_hash[:publisher].present?

        # Add series information if it exists.
        if pub_hash.key?(:series)
          if pub_hash[:series][:title].present?
            cit_data_hash['type'] = 'book'
            cit_data_hash['collection-title'] = pub_hash[:series][:title]
          end
          cit_data_hash['volume'] = pub_hash[:series][:volume] if pub_hash[:series][:volume].present?
          cit_data_hash['number'] = pub_hash[:series][:number] if pub_hash[:series][:number].present?
          cit_data_hash['issued'] = { 'date-parts' => [[pub_hash[:series][:year]]] } if pub_hash[:series][:year].present?
        end

        # Add journal information if it exists.
        if pub_hash.key?(:journal)
          if pub_hash[:journal][:name].present?
            cit_data_hash['type'] = 'article-journal'
            cit_data_hash['container-title'] = pub_hash[:journal][:name]
          end
          cit_data_hash['volume'] = pub_hash[:journal][:volume] if pub_hash[:journal][:volume].present?
          cit_data_hash['issue'] = pub_hash[:journal][:issue] if pub_hash[:journal][:issue].present?
          cit_data_hash['issued'] = { 'date-parts' => [[pub_hash[:journal][:year]]] } if pub_hash[:journal][:year].present?
          cit_data_hash['number'] = pub_hash[:supplement] if pub_hash[:supplement].present?
        end

        # Add any conference information, if it exists in a conference object;
        # this overrides the sciencewire fields above if both exist, which they shouldn't.
        if pub_hash.key?(:conference)
          cit_data_hash['event'] = pub_hash[:conference][:name] if pub_hash[:conference][:name].present?
          cit_data_hash['event-date'] = pub_hash[:conference][:startdate] if pub_hash[:conference][:startdate].present?
          # override the startdate if there is a year:
          cit_data_hash['event-date'] = { 'date-parts' => [[pub_hash[:conference][:year]]] } if pub_hash[:conference][:year].present?
          cit_data_hash['number'] = pub_hash[:conference][:number] if pub_hash[:conference][:number].present?
          # favors city/state over location
          if pub_hash[:conference][:city].present? || pub_hash[:conference][:statecountry].present?
            cit_data_hash['event-place'] = pub_hash[:conference][:city] || ''
            if pub_hash[:conference][:statecountry].present?
              cit_data_hash['event-place'] << ',' if cit_data_hash['event-place'].present?
              cit_data_hash['event-place'] << pub_hash[:conference][:statecountry]
            end
          elsif pub_hash[:conference][:location].present?
            cit_data_hash['event-place'] = pub_hash[:conference][:location]
          end
          # cit_data_hash["DOI"] = pub_hash[:conference][:DOI] if pub_hash[:conference][:DOI].present?
        end

        # Use a year at the top level if it exists, i.e, override any year we'd gotten above from journal or series.
        cit_data_hash['issued'] = { 'date-parts' => [[pub_hash[:year]]] } if pub_hash[:year].present?
        # Add book title if it exists, which indicates this pub is a chapter in the book.
        if pub_hash[:booktitle].present?
          cit_data_hash['type'] = 'book'
          cit_data_hash['container-title'] = pub_hash[:booktitle]
        end

        cit_data_hash['editor'] = citeproc_editors if cit_data_hash['type'].eql?('book') && citeproc_editors.present?

        ##
        # For a CAP type "caseStudy" just use a "book"
        cit_data_hash['type'] = 'book' if pub_hash[:type].to_s.downcase.eql?('casestudy')

        ##
        # Mapping custom fields from the CAP system.
        cit_data_hash['URL'] = pub_hash[:publicationUrl] if pub_hash[:publicationUrl].present?
        cit_data_hash['publisher-place'] = pub_hash[:publicationSource] if pub_hash[:publicationSource].present?

        cit_data_hash
      end
    end

    private

      def citeproc_authors
        @citeproc_authors ||= parse_authors[:authors]
      end

      def citeproc_editors
        @citeproc_editors ||= parse_authors[:editors]
      end

      def parse_authors
        # All the pub_hash[:author] data is assumed be an editor or an author and
        # the only way to tell is when the editor has role=='editor'
        pub_hash_authors = pub_hash[:author] || []
        authors = pub_hash_authors.reject { |a| a[:role].to_s.downcase.eql?('editor') }
        editors = pub_hash_authors.select { |a| a[:role].to_s.downcase.eql?('editor') }
        if authors.length > 5
          # we pass the first five  authorsand the very last author because some
          # formats add the very last name when using et-al. the CSL should drop the sixth name if unused.
          # We could in fact pass all the author names to the CSL processor and let it
          # just take the first five, but that seemed to crash the processor for publications
          # with a lot of authors (e.g, 2000 authors)
          authors = authors[0..4]
          authors << pub_hash[:author].last
          #   authors << { :name => "et al." }
          # elsif pub_hash[:etal]
          #   authors = pub_hash[:author].collect { |a| a }
          #   authors << { :name => "et al." }
        end
        {
          authors: authors.map { |author| parse_author_name(author) }.compact,
          editors: editors.map { |author| parse_author_name(author) }.compact
        }
      end

      # Extract { 'family' => last_name, 'given' => rest_of_name } or
      # return nil if the the family name is blank.
      # @return [Hash<String => String>|nil]
      def parse_author_name(author)
        last_name = author[:lastname]
        rest_of_name = ''

        # Use parsed name parts, if available.  Otherwise use :name, if available.
        # Add period after single character (initials).
        if last_name.present?
          %i(firstname middlename).map { |k| author[k] }.reject(&:blank?).each do |name_part|
            rest_of_name << ' ' << name_part
            rest_of_name << '.' if name_part.length == 1
          end
        end

        if last_name.blank? && author[:name].present?
          author[:name].split(',').each_with_index do |name_part, index|
            if index.zero?
              last_name = name_part
            else
              rest_of_name << ' ' << name_part
              rest_of_name << '.' if name_part.length == 1
            end
          end
        end

        return nil if last_name.blank?
        { 'family' => last_name, 'given' => rest_of_name }
      end
  end

end

