# frozen_string_literal: true

module Csl
  class Mapper
    attr_reader :pub_hash

    # @param pub_hash [Hash] a Publication.pub_hash
    def initialize(pub_hash)
      @pub_hash = pub_hash
    end

    # rubocop:disable Metrics/AbcSize
    def csl_doc
      @csl_doc ||= begin
        if pub_hash[:provenance].to_s.downcase == 'cap'
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
          if pub_hash[:series][:year].present?
            cit_data_hash['issued'] =
              { 'date-parts' => [[pub_hash[:series][:year]]] }
          end
        end

        # Add journal information if it exists.
        if pub_hash.key?(:journal)
          if pub_hash[:journal][:name].present?
            cit_data_hash['type'] = 'article-journal'
            cit_data_hash['container-title'] = pub_hash[:journal][:name]
          end
          cit_data_hash['volume'] = pub_hash[:journal][:volume] if pub_hash[:journal][:volume].present?
          cit_data_hash['issue'] = pub_hash[:journal][:issue] if pub_hash[:journal][:issue].present?
          if pub_hash[:journal][:year].present?
            cit_data_hash['issued'] =
              { 'date-parts' => [[pub_hash[:journal][:year]]] }
          end
          cit_data_hash['number'] = pub_hash[:supplement] if pub_hash[:supplement].present?
        end

        # Add any conference information, if it exists in a conference object;
        # this overrides the sciencewire fields above if both exist, which they shouldn't.
        if pub_hash.key?(:conference)
          cit_data_hash['event'] = pub_hash[:conference][:name] if pub_hash[:conference][:name].present?
          cit_data_hash['event-date'] = pub_hash[:conference][:startdate] if pub_hash[:conference][:startdate].present?
          # override the startdate if there is a year:
          if pub_hash[:conference][:year].present?
            cit_data_hash['event-date'] =
              { 'date-parts' => [[pub_hash[:conference][:year]]] }
          end
          cit_data_hash['number'] = pub_hash[:conference][:number] if pub_hash[:conference][:number].present?
          # favors city/state over location
          if pub_hash[:conference][:city].present? || pub_hash[:conference][:statecountry].present?
            cit_data_hash['event-place'] = pub_hash[:conference][:city] || ''
            if pub_hash[:conference][:statecountry].present?
              cit_data_hash['event-place'] = "#{cit_data_hash['event-place']}," if cit_data_hash['event-place'].present?
              cit_data_hash['event-place'] = "#{cit_data_hash['event-place']}#{pub_hash[:conference][:statecountry]}"
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
    # rubocop:enable Metrics/AbcSize

    private

    def citeproc_authors
      @citeproc_authors ||= Csl::RoleMapper.authors(pub_hash)
    end

    def citeproc_editors
      @citeproc_editors ||= Csl::RoleMapper.editors(pub_hash)
    end
  end
end
