require 'spec_helper'
SingleCov.covered!

describe PubHash do
  include CitationDocumentTypes # spec/fixtures/doc_types/working_paper.rb

  let(:conference_pub_in_journal_hash) do
    { title: 'My test title',
      type: 'paper-conference',
      articlenumber: 33,
      pages: '33-56',
      author: [{ name: 'Smith, Jack', role: 'editor' },
               { name: 'Sprat, Jill', role: 'editor' },
               { name: 'Jones, P. L.' },
               { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
      year: '1987',
      supplement: '33',
      publisher: 'Some Publisher',
      journal: { name: 'Some Journal Name', volume: 33, issue: 32, year: 1999 },
      conference: { name: 'The Big Conference', year: 2345, number: 33, location: 'Knoxville, TN', city: 'Knoxville', statecountry: 'TN' }
    }
  end

  let(:conference_pub_in_book_hash) do
    { title: 'My test title',
      type: 'paper-conference',
      articlenumber: 33,
      pages: '33-56',
      author: [{ name: 'Smith, Jack', role: 'editor' },
               { name: 'Sprat, Jill', role: 'editor' },
               { name: 'Jones, P. L.' },
               { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
      year: '1987',
      publisher: 'Smith Books',
      booktitle: 'The Giant Book of Giant Ideas',
      conference: { name: 'The Big Conference', year: 2345, number: 33, location: 'Knoxville, TN', city: 'Knoxville', statecountry: 'TN' }
    }
  end

  let(:conference_pub_in_series_hash) do
    { title: 'My test title',
      type: 'paper-conference',
      articlenumber: 33,
      pages: '33-56',
      author: [{ name: 'Smith, Jack', role: 'editor' },
               { name: 'Sprat, Jill', role: 'editor' },
               { name: 'Jones, P. L.' },
               { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
      year: '1987',
      publisher: 'Smith Books',
      booktitle: 'The Giant Book of Giant Ideas',
      conference: { name: 'The Big Conference', year: 2345, number: 33, location: 'Knoxville, TN', city: 'Knoxville', statecountry: 'TN' },
      series: { title: 'The book series for kings and queens', volume: 1, number: 4, year: 1933 }
    }
  end

  let(:conference_pub_in_nothing_hash) do
    { title: 'My test title',
      type: 'speech',
      author: [
        { name: 'Jones, P. L.' },
        { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
      conference: { name: 'The Big Conference', year: '1999', number: 33, location: 'Knoxville, TN', city: 'Knoxville', statecountry: 'TN' }
    }
  end

  let(:book_pub_hash) do
    { title: 'My test title',
      type: 'book',
      author: [
        { name: 'Jones, P. L.' },
        { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
      year: '1987',
      publisher: 'Smith Books',
      booktitle: 'The Giant Book of Giant Ideas'
    }
  end

  let(:book_pub_with_editors_hash) do
    { title: 'My test title',
      type: 'book',
      author: [{ name: 'Smith, Jack', role: 'editor' },
               { name: 'Sprat, Jill', role: 'editor' },
               { name: 'Jones, P. L.' },
               { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
      year: '1987',
      publisher: 'Smith Books',
      booktitle: 'The Giant Book of Giant Ideas'
    }
  end

  let(:series_pub_hash) do
    { title: 'My test title',
      type: 'book',
      author: [{ name: 'Smith, Jack', role: 'editor' },
               { name: 'Sprat, Jill', role: 'editor' },
               { name: 'Jones, P. L.' },
               { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
      year: '1987',
      publisher: 'Smith Books',
      booktitle: 'The Giant Book of Giant Ideas',
      series: { title: 'The book series for Big Ideas', volume: 1, number: 4, year: 1933 }
    }
  end

  let(:article_pub_hash) do
    { title: 'My test title',
      type: 'article',
      pages: '3-6',
      author: [{ name: 'Smith, Jack', role: 'editor' },
               { name: 'Sprat, Jill', role: 'editor' },
               { name: 'Jones, P. L.' },
               { firstname: 'Alan', middlename: 'T', lastname: 'Jackson' }],
      year: '1987',
      publisher: 'Some Publisher',
      journal: { name: 'Some Journal Name', volume: 33, issue: 32, year: 1999 }
    }
  end

  let(:pub_hash) do
    { provenance: 'sciencewire',
      pmid: '15572175',
      sw_id: '6787731',
      title: 'New insights into the expression and function of neural connexins with transgenic mouse mutants',
      abstract_restricted:       'Gap junctions represent direct intercellular conduits between contacting cells. The subunit proteins of these conduits are called connexins. To date, 20 and 21 connexin genes have been described in the mouse and human genome, respectiv',
      author: [
        { name: 'Sohl,G,' },
        { name: 'Odermatt,B,' },
        { name: 'Maxeiner,S,' },
        { name: 'Degen,J,' },
        { name: 'Willecke,K,' },
        { name: 'SecondLast,T,' },
        { name: 'Last,O,' }
      ],
      year: '2004',
      date: '2004-12-01T00:00:00',
      authorcount: '6',
      documenttypes_sw: ['Article'],
      type: 'article',
      documentcategory_sw: 'Conference Proceeding Document',
      publicationimpactfactorlist_sw:       ['4.617,2004,ExactPublicationYear', '10.342,2011,MostRecentYear'],
      publicationcategoryrankinglist_sw:       ['28/198;NEUROSCIENCES;2004;SC;ExactPublicationYear',
                                                '10/242;NEUROSCIENCES;2011;SC;MostRecentYear'],
      numberofreferences_sw: '159',
      timescited_sw_retricted: '40',
      timenotselfcited_sw: '30',
      authorcitationcountlist_sw: '1,2,38|2,0,40|3,3,37|4,0,40|5,10,30',
      rank_sw: '',
      ordinalrank_sw: '67',
      normalizedrank_sw: '',
      newpublicationid_sw: '',
      isobsolete_sw: 'false',
      publisher: 'ELSEVIER SCIENCE BV',
      city: 'AMSTERDAM',
      stateprovince: '',
      country: 'NETHERLANDS',
      pages: '245-259',
      issn: '0165-0173',
      journal:       { name: 'BRAIN RESEARCH REVIEWS',
                       volume: '47',
                       issue: '1-3',
                       pages: '245-259',
                       identifier:         [{ type: 'issn',
                                              id: '0165-0173',
                                              url: Settings.SULPUB_ID.SEARCHWORKS_URI + '0165-0173' },
                                            { type: 'doi',
                                              id: '10.1016/j.brainresrev.2004.05.006',
                                              url: 'http://dx.doi.org/10.1016/j.brainresrev.2004.05.006' }] },
      abstract:       'Gap junctions represent direct intercellular conduits between contacting cells. The subunit proteins of these conduits are called connexins. To date, 20 and 21 connexin genes have been described in the mouse and human genome, respectiv',
      last_updated: '2013-07-23 22:06:49 UTC',
      authorship:       [{ cap_profile_id: 8804,
                           sul_author_id: 2579,
                           status: 'unknown',
                           visibility: 'private',
                           featured: false }]
    }
  end
  let(:technical_report_online_pub_hash) do
    {
      title: 'Laws of Attrition: Crackdown on Russia’s Civil Society After Putin’s Return to the Presidency',
      type: 'technicalReport',
      provenance: 'CAP',
      pages: '',
      author: [
        {
          name: 'Gorbunova Yulia',
          lastname: 'Gorbunova',
          firstname: 'Yulia',
          middlename: '',
          alternate: [],
          role: 'author',
          additionalProperties: {}
        }
      ],
      year: '2013',
      publisher: 'Human Rights Watch',
      publicationUrl: 'http://www.hrw.org/reports/2013/04/24/laws-attrition',
      publicationUrlLabel: '',
      publicationSource: 'New York'
    }
  end
  let(:technical_report_print_pub_hash) do
    {
      title: 'Laws of Attrition: Crackdown on Russia’s Civil Society After Putin’s Return to the Presidency',
      type: 'technicalReport',
      provenance: 'CAP',
      author: [
        {
          name: 'Gorbunova Yulia',
          lastname: 'Gorbunova',
          firstname: 'Yulia',
          middlename: '',
          alternate: [],
          role: 'author',
          additionalProperties: {}
        },
        {
          name: 'Baranov Konstantin',
          lastname: 'Baranov',
          firstname: 'Konstantin',
          middlename: '',
          alternate: [],
          role: 'author',
          additionalProperties: {}
        }
      ],
      year: '2013',
      publisher: 'Human Rights Watch',
      publicationUrl: '',
      publicationUrlLabel: '',
      publicationSource: 'New York'
    }
  end
  let(:case_study_pub_hash) do
    {
      title: 'HCL Technologies',
      type: 'caseStudy',
      provenance: 'CAP',
      author: [
        {
          name: 'Hill  Linda',
          lastname: 'Hill',
          firstname: 'Linda',
          middlename: '',
          alternate: [],
          role: 'author',
          additionalProperties: {}
        },
        {
          name: 'Khanna  Tarun',
          lastname: 'Khanna',
          firstname: 'Tarun',
          middlename: '',
          alternate: [],
          role: 'author',
          additionalProperties: {}
        },
        {
          name: 'Stecker A Emily',
          lastname: 'Stecker',
          firstname: 'Emily',
          middlename: 'A',
          alternate: [],
          role: 'author',
          additionalProperties: {}
        }
      ],
      year: '2008',
      publisher: 'Harvard Business Publishing',
      publicationSource: 'Boston'
    }
  end

  # describe "#sync_publication_hash" do
  #   context " with multiple contributions " do
  #
  #     it " writes the correct authorship field to the pub_hash "
  #         pending
  #       end
  #     it " creates a new contribution for a new authorship entry in the pub_hash "
  #         pending
  #       end
  #   end
  # end

  shared_examples 'it is a CSL report citation' do
    def expect_includes_field(field)
      expect(cite).to include(csl_report[field]) if csl_report[field]
    end
    it 'includes title' do
      # Check title without case sensitivity because this is very hard to do
      # and the CSL style is likely the authority on how to do it anyway.
      expect(cite).to match(/#{csl_report['title']}/i)
    end
    it 'does not include an abstract' do
      expect(cite).not_to include(csl_report['abstract']) if csl_report['abstract']
    end
    it 'includes author family names' do
      # Given variations in citation styles, it's not easy to check for all
      # citation details on names, so just check the last names here.  Specs
      # on each citation style can check more specific details.
      csl_report['author'].each do |author|
        expect(cite).to include(author['family'])
      end
    end
    it 'includes collection-title' do
      expect_includes_field('collection-title')
    end
    it 'includes number' do
      expect_includes_field('number')
    end
    it 'includes page' do
      expect_includes_field('page')
    end
    it 'includes publisher' do
      expect_includes_field('publisher')
    end
    it 'includes publisher-place' do
      expect_includes_field('publisher-place')
    end
    it 'includes URL' do
      expect_includes_field('URL')
    end
    it 'includes year' do
      year = csl_report['issued']['date-parts'].first.first
      expect(cite).to include(year)
    end
  end

  context 'CiteProc citation for working paper (report)' do
    context 'CSL report for hurricane working paper generates an acceptable APA citation' do
      let(:csl_renderer) { CiteProc::Ruby::Renderer.new format: 'html' }
      let(:csl_style) { CSL::Style.load('apa') }
      let(:cite) do
        item = CiteProc::CitationItem.new id: 'sulpub'
        item.data = CiteProc::Item.new(csl_report)
        csl_renderer.render item, csl_style.bibliography
      end
      let(:csl_report) do
        # from spec/fixtures/doc_types/working_paper.rb
        working_paper_for_hurricanes_as_csl_report
      end
      it 'includes authors' do
        csl_report['author'].each do |a|
          given = a['given'].split.map {|i| i[0] + '.'}.join(' ')
          name = "#{a['family']}, #{given}"
          expect(cite).to include(name)
        end
      end
      it_behaves_like 'it is a CSL report citation'
      it 'closely matches sul-pub requirements' do
        # The CSL citation does not exactly match the citation details initially
        # defined, which included some variations from APA standards.  The CSL
        # tools will not allow custom modifications.
        sul_authors = "Imberman, S., Kugler, A. D., &amp; Sacerdote, B. (2009)."
        sul_title = "Katrina's children: evidence on the structure of peer effects from hurricane evacuees"
        sul_number = '(Working Paper No. 15291)' # 'Working Paper' is not in APA standard
        sul_website = "Retrieved from National Bureau of Economic Research website: http://www.nber.org/papers/w15291"
        # Variations in the CSL citation content:
        csl_series_number = '(NBER Working Paper Series No. 15291)'
        csl_page = '(pp. 1–55).'
        csl_publisher = 'National Bureau of Economic Research.'
        csl_publisher_place = 'Cambridge, MA'
        csl_website = 'Retrieved from http://www.nber.org/papers/w15291'
        # Expect specific inclusions
        expect(cite).to include(sul_authors)
        expect(cite).to match(/#{sul_title}/i) # case insenstive match
        expect(cite).to include(csl_series_number)
        expect(cite).not_to include(sul_number)
        expect(cite).to include(csl_page)
        expect(cite).to include(csl_publisher)
        expect(cite).to include(csl_publisher_place)
        expect(cite).to include(csl_website)
        expect(cite).not_to include(sul_website)
        # Expect a complete citation
        expect(cite).to eq "Imberman, S., Kugler, A. D., &amp; Sacerdote, B. (2009). <i>Katrina's Children: Evidence on the Structure of Peer Effects from Hurricane Evacuees</i> (NBER Working Paper Series No. 15291) (pp. 1–55). Cambridge, MA: National Bureau of Economic Research. Retrieved from http://www.nber.org/papers/w15291"
      end
    end

    context 'CAP working paper for hurricanes' do
      let(:pub_hash) do
        # from spec/fixtures/doc_types/working_paper.rb
        hash = JSON.parse(working_paper_for_hurricanes.to_json, symbolize_names: true)
        PubHash.new(hash)
      end
      let(:target_csl_report) do
        # from spec/fixtures/doc_types/working_paper.rb
        working_paper_for_hurricanes_as_csl_report
      end
      let(:csl_report) { pub_hash.csl_doc }
      let(:cite) { pub_hash.to_apa_citation }
      it_behaves_like 'it is a CSL report citation'
      context 'translates to a CSL report document' do
        def expect_field_match(field)
          expect(csl_report[field]).to eq target_csl_report[field]
        end
        it 'matches "abstract"' do
          expect_field_match('abstract')
        end
        it 'matches "author"' do
          expect_field_match('author')
        end
        it 'matches "collection-title"' do
          expect_field_match('collection-title')
        end
        it 'matches "id"' do
          expect_field_match('id')
        end
        it 'matches "issued"' do
          expect_field_match('issued')
        end
        it 'matches "number"' do
          expect_field_match('number')
        end
        it 'matches "page"' do
          expect_field_match('page')
        end
        it 'matches "publisher"' do
          expect_field_match('publisher')
        end
        it 'matches "title"' do
          expect_field_match('title')
        end
        it 'matches "type"' do
          expect_field_match('type')
        end
        it 'matches "URL"' do
          expect_field_match('URL')
        end
      end
      it 'creates an APA citation' do
        expect(pub_hash.to_apa_citation)
          .to eq "Imberman, S., Kugler, A. D., &amp; Sacerdote, B. (2009). <i>Katrina's Children: Evidence on the Structure of Peer Effects from Hurricane Evacuees</i> (NBER Working Paper Series No. 15291) (pp. 1–55). Cambridge, MA: National Bureau of Economic Research. Retrieved from http://www.nber.org/papers/w15291"
      end
      it 'creates a Chicago citation' do
        expect(pub_hash.to_chicago_citation)
          .to eq "Imberman, Scott, Adriana D. Kugler, and Bruce Sacerdote. 2009. “Katrina's Children: Evidence on the Structure of Peer Effects from Hurricane Evacuees.” 15291. NBER Working Paper Series. Cambridge, MA: National Bureau of Economic Research. http://www.nber.org/papers/w15291."
      end
      it 'creates an MLA citation' do
        expect(pub_hash.to_mla_citation)
          .to eq "Imberman, Scott, Adriana D. Kugler, and Bruce Sacerdote. <i>Katrina's Children: Evidence on the Structure of Peer Effects from Hurricane Evacuees</i>. Cambridge, MA: National Bureau of Economic Research, 2009. Web. NBER Working Paper Series."
      end
    end

    ##
    # An example given from a direct import of a record entered in the CAP UAT environment.
    context 'CAP working paper for Revs Digital Library' do
      let(:working_paper) { create(:working_paper) }
      let(:pub_hash) { PubHash.new(JSON.parse(working_paper.source_data, symbolize_names: true)) }
      it 'creates an APA citation' do
        expect(pub_hash.to_apa_citation)
          .to eq "Mangiafico, P. A. (2016). <i>This is Peter's Working Paper on the Revs Digital Library</i> (Series Name No. Series Number) (p. 5). Stanford, CA: Stanford University. Retrieved from http://revslib.stanford.edu"
      end
      it 'creates a Chicago citation' do
        expect(pub_hash.to_chicago_citation)
          .to eq "Mangiafico, Peter A. 2016. “This Is Peter's Working Paper on the Revs Digital Library.” Series Number. Series Name. Stanford, CA: Stanford University. http://revslib.stanford.edu."
      end
      it 'creates an MLA citation' do
        expect(pub_hash.to_mla_citation)
          .to eq "Mangiafico, Peter A. <i>This Is Peter's Working Paper on the Revs Digital Library</i>. Stanford, CA: Stanford University, 2016. Web. Series Name."
      end
    end
  end

  describe '#to_chicago_citation' do
    context 'with more than 5 authors' do
      let(:hash) { PubHash.new(pub_hash) }
      let(:cite) { hash.to_chicago_citation }
      it 'builds citations with just the first 5 and suppends et al' do
        expect(cite).to match(/^Sohl, G./)
        expect(cite).to include('B. Odermatt')
        expect(cite).to include('S. Maxeiner')
        expect(cite).to include('J. Degen')
        expect(cite).to include('K. Willecke')
        expect(cite).to include('et al.')
        expect(cite).to_not include(', and')
        expect(cite).to_not include('SecondLast')
        expect(cite).to_not include('Last')
        expect(hash.pub_hash[:author]).to_not include(name: 'et al.')
      end
      it 'creates a Chicago citation' do
        expect(cite).to eq 'Sohl, G., B. Odermatt, S. Maxeiner, J. Degen, K. Willecke, et al. 2004. “New Insights into the Expression and Function of Neural Connexins with Transgenic Mouse Mutants.” <i>BRAIN RESEARCH REVIEWS</i> 47 (1-3). ELSEVIER SCIENCE BV: 245–59.'
      end
    end

    it 'includes capitalized title' do
      h = PubHash.new(pub_hash)
      cite = h.to_chicago_citation
      expect(cite).to include('New Insights into the Expression and Function of Neural Connexins with Transgenic Mouse Mutants')
    end

    it 'includes authors from single name field' do
      h = PubHash.new(article_pub_hash)
      cite = h.to_chicago_citation
      expect(cite).to match(/Jones,\s+P. L./)
    end
    pending 'builds citations with first author name spacing correct' do
      h = PubHash.new(article_pub_hash)
      cite = h.to_chicago_citation
      expect(cite).to match(/^Jones, P. L./)
    end

    it 'includes authors from compound name field' do
      h = PubHash.new(article_pub_hash)
      cite = h.to_chicago_citation
      expect(cite).to include('Alan T. Jackson')
    end

    context 'for conference' do
      context 'published in book' do
        it 'includes book information' do
          conference_in_book = PubHash.new(conference_pub_in_book_hash)
          cite = conference_in_book.to_chicago_citation
          expect(cite).to include(conference_pub_in_book_hash[:booktitle])
          expect(cite).to include(conference_pub_in_book_hash[:publisher])
          expect(cite).to include(conference_pub_in_book_hash[:year])
        end
      end

      context 'published in journal' do
        it 'includes journal information' do
          conference_in_journal = PubHash.new(conference_pub_in_journal_hash)
          cite = conference_in_journal.to_chicago_citation
          expect(cite).to include(conference_pub_in_journal_hash[:title].titlecase)
          expect(cite).to include(conference_pub_in_journal_hash[:pages])
          expect(cite).to include(conference_pub_in_journal_hash[:year])
          expect(cite).to include(conference_pub_in_journal_hash[:journal][:name])
        end
      end

      context 'published in book series' do
        it 'includes book and series information' do
          conference_in_book_series = PubHash.new(conference_pub_in_series_hash)
          cite = conference_in_book_series.to_chicago_citation
          expect(cite).to include('The Giant Book of Giant Ideas')
          expect(cite).to include('The Book Series for Kings and Queens')
          expect(cite).to include(conference_pub_in_series_hash[:publisher])
          expect(cite).to include(conference_pub_in_series_hash[:year])
        end
      end
    end

    context 'for book' do
      let(:book) { PubHash.new(book_pub_hash) }
      let(:cite) { book.to_chicago_citation }
      it 'includes book information' do
        expect(cite).to include(book_pub_hash[:booktitle])
        expect(cite).to include(book_pub_hash[:publisher])
        expect(cite).to include(book_pub_hash[:year])
      end
      it 'includes editors' do
        book = PubHash.new(book_pub_with_editors_hash)
        cite = book.to_chicago_citation
        expect(cite).to include('Jack Smith')
        expect(cite).to include('Jill Sprat')
      end
      it 'includes authors' do
        expect(cite).to match(/^Jones,\s+P. L./)
        expect(cite).to include('Alan T. Jackson')
      end
      pending 'builds citations with first author name spacing correct' do
        expect(cite).to match(/^Jones, P. L./)
      end
    end

    context 'for article' do
      let(:article_in_journal) { PubHash.new(article_pub_hash) }
      let(:cite) { article_in_journal.to_chicago_citation }
      it 'includes article information' do
        expect(cite).to include(article_pub_hash[:title].titlecase)
        expect(cite).to include(article_pub_hash[:year])
        expect(cite).to include(article_pub_hash[:journal][:name])
      end
      it 'includes journal volume issue and pages' do
        expect(cite).to include("#{article_pub_hash[:journal][:volume]} (#{article_pub_hash[:journal][:issue]})")
        expect(cite).to include(article_pub_hash[:pages])
      end
      it 'excludes editors' do
        expect(cite).to_not include('Jack Smith')
        expect(cite).to_not include('Jill Sprat')
      end
      it 'includes authors' do
        expect(cite).to match(/Jones,\s+P. L./)
        expect(cite).to include('Alan T. Jackson')
      end
      pending 'builds citations with first author name spacing correct' do
        expect(cite).to match(/^Jones, P. L./)
      end
      it 'creates a Chicago citation' do
        expect(cite).to eq 'Jones,   P. L., and Alan T. Jackson. 1987. “My Test Title.” <i>Some Journal Name</i> 33 (32). Some Publisher: 3–6.'
      end
    end
  end

  describe '#to_mla_citation' do
    context 'with more than 5 authors' do
      let(:hash) { PubHash.new(pub_hash) }
      let(:cite) { hash.to_mla_citation }
      it 'builds citations with just the first 5' do
        expect(cite).to match(/^Sohl, G./)
        expect(hash.pub_hash[:author]).to_not include(name: 'et al.')
      end
    end

    context 'with etal flag' do
      let(:et_hash) do
        { provenance: 'sciencewire',
          pmid: '15572175',
          sw_id: '6787731',
          title:         'New insights into the expression and function of neural connexins with transgenic mouse mutants',
          abstract_restricted:         'Gap junctions represent direct intercellular conduits between contacting cells. The subunit proteins of these conduits are called connexins. To date, 20 and 21 connexin genes have been described in the mouse and human genome, respectiv',
          author:         [{ name: 'Sohl,G,' },
                           { name: 'Odermatt,B,' }],
          etal: true,
          year: '2004',
          date: '2004-12-01T00:00:00',
          authorcount: '6',
          documenttypes_sw: ['Article'],
          type: 'article',
          documentcategory_sw: 'Conference Proceeding Document',
          numberofreferences_sw: '159',
          publisher: 'ELSEVIER SCIENCE BV',
          city: 'AMSTERDAM',
          stateprovince: '',
          country: 'NETHERLANDS',
          pages: '245-259',
          issn: '0165-0173',
          journal:           { name: 'BRAIN RESEARCH REVIEWS',
                               volume: '47',
                               issue: '1-3',
                               pages: '245-259',
                               identifier:             [{ type: 'issn',
                                                          id: '0165-0173',
                                                          url: Settings.SULPUB_ID.SEARCHWORKS_URI + '0165-0173' },
                                                        { type: 'doi',
                                                          id: '10.1016/j.brainresrev.2004.05.006',
                                                          url: 'http://dx.doi.org/10.1016/j.brainresrev.2004.05.006' }] },
          abstract:                 'Gap junctions represent direct intercellular conduits between contacting cells. The subunit proteins of these conduits are called connexins. To date, 20 and 21 connexin genes have been described in the mouse and human genome, respectiv',
          last_updated: '2013-07-23 22:06:49 UTC',
          authorship:                 [{ cap_profile_id: 8804,
                                         sul_author_id: 2579,
                                         status: 'unknown',
                                         visibility: 'private',
                                         featured: false }]
                  }
      end

      it 'adds et al whenever the flag is true' do
        skip 'have to further modify CSL or code somehow'
        h = PubHash.new(et_hash)
        cite = h.to_chicago_citation
        expect(cite).to match(/^Sohl, G./)
        expect(cite).to match(/et al./)
        expect(h.pub_hash[:author]).to_not include(name: 'et al.')
      end
    end
  end

  describe 'Other paper' do
    let(:other_paper) { create(:other_paper) }
    context 'from cap' do
      let(:pub_hash) { PubHash.new(JSON.parse(other_paper.source_data, symbolize_names: true)) }
      it 'creates a Chicago citation' do
        expect(pub_hash.to_chicago_citation)
          .to eq "Mangiafico, Peter A. 2016. <i>This Is Peter's Other Paper on the Revs Digital Library</i>. Series Name. Stanford, CA: Stanford University. http://revslib.stanford.edu."
      end
      it 'creates a MLA citation' do
        expect(pub_hash.to_mla_citation)
          .to eq "Mangiafico, Peter A. <i>This Is Peter's Other Paper on the Revs Digital Library</i>. Stanford, CA: Stanford University, 2016. Web. Series Name."
      end
      it 'creates an APA citation' do
        expect(pub_hash.to_apa_citation)
          .to eq "Mangiafico, P. A. (2016). <i>This is Peter's Other Paper on the Revs Digital Library</i> (pp. 1–5). Stanford, CA: Stanford University. Retrieved from http://revslib.stanford.edu"
      end
    end
  end

  describe 'Technical report' do
    let(:technical_report) { create(:technical_report) }
    ##
    # An example given from a direct import of a record entered in the CAP UAT environment.
    context 'from cap with minimum required fields' do
      let(:pub_hash) { PubHash.new(JSON.parse(technical_report.source_data, symbolize_names: true)) }
      it 'creates an APA citation' do
        expect(pub_hash.to_apa_citation)
          .to eq "Mangiafico, P. A. (2016). <i>This is Peter's Technical Report on the Revs Digital Library</i> (Series Name No. 5) (pp. 1–5). Stanford, CA : Stanford University. Retrieved from http://revslib.stanford.edu"
      end
      it 'creates a Chicago citation' do
        expect(pub_hash.to_chicago_citation)
          .to eq "Mangiafico, Peter A. 2016. “This Is Peter's Technical Report on the Revs Digital Library.” 5. Series Name. Stanford, CA : Stanford University. http://revslib.stanford.edu."
      end
      it 'creates an MLA citation' do
        expect(pub_hash.to_mla_citation)
          .to eq "Mangiafico, Peter A. <i>This Is Peter's Technical Report on the Revs Digital Library</i>. Stanford, CA : Stanford University, 2016. Web. Series Name."
      end
    end

    context 'given fixture' do
      context 'an online technical report' do
        let(:pub_hash) { PubHash.new(technical_report_online_pub_hash) }
        ##
        # Example taken from: http://www.easybib.com/guides/citation-guides/chicago-turabian/how-to-cite-a-report-chicago-turabian/
        # Differences: using the Sul-Pub preferred Chicago author-date format
        it 'creates a Chicago citation' do
          expect(pub_hash.to_chicago_citation)
            .to eq "Gorbunova, Yulia. 2013. “Laws of Attrition: Crackdown on Russia’s Civil Society After Putin’s Return to the Presidency.” New York: Human Rights Watch. http://www.hrw.org/reports/2013/04/24/laws-attrition."
        end
        ##
        # Example taken from: http://www.easybib.com/guides/citation-guides/apa-format/how-to-cite-a-report-apa/
        # Differences: not showing "Retrieved from 'Agency name' website:"
        it 'creates an APA citation' do
          expect(pub_hash.to_apa_citation)
            .to eq 'Gorbunova, Y. (2013). <i>Laws of Attrition: Crackdown on Russia’s Civil Society After Putin’s Return to the Presidency</i>. New York: Human Rights Watch. Retrieved from http://www.hrw.org/reports/2013/04/24/laws-attrition'
        end
        ##
        # http://www.easybib.com/guides/citation-guides/mla-format/how-to-cite-a-report-mla/
        it 'creates a MLA citation' do
          expect(pub_hash.to_mla_citation)
            .to eq "Gorbunova, Yulia. <i>Laws of Attrition: Crackdown on Russia’s Civil Society After Putin’s Return to the Presidency</i>. New York: Human Rights Watch, 2013. Web."
        end
      end

      ##
      # Example take from: http://www.easybib.com/guides/citation-guides/mla-format/how-to-cite-a-report-mla/
      # Differences: using a modified multiple authors format that we already support
      context 'a print technical report with multiple authors' do
        let(:pub_hash) { PubHash.new(technical_report_print_pub_hash) }
        it 'creates a MLA citation' do
          expect(pub_hash.to_mla_citation)
            .to eq "Gorbunova, Yulia, and Konstantin Baranov. <i>Laws of Attrition: Crackdown on Russia’s Civil Society After Putin’s Return to the Presidency</i>. New York: Human Rights Watch, 2013. Print."
        end
      end
    end
  end

  describe 'Case Studies' do
    let(:case_study) { create(:case_study) }
    context 'with minimum required fields' do
      let(:pub_hash) { PubHash.new(JSON.parse(case_study.source_data, symbolize_names: true)) }
      it 'creates a chicago citation' do
        expect(pub_hash.to_chicago_citation)
          .to eq "Mangiafico, Peter A. 2016. <i>This Is Peter's Case Study on the Revs Digital Library</i>. Series Name. Stanford, CA: Stanford University. http://revslib.stanford.edu."
      end
      it 'creates a MLA citation' do
        expect(pub_hash.to_mla_citation)
          .to eq "Mangiafico, Peter A. <i>This Is Peter's Case Study on the Revs Digital Library</i>. Stanford, CA: Stanford University, 2016. Web. Series Name."
      end
      it 'creates a APA citation' do
        expect(pub_hash.to_apa_citation)
          .to eq "Mangiafico, P. A. (2016). <i>This is Peter's Case Study on the Revs Digital Library</i> (pp. 1–5). Stanford, CA: Stanford University. Retrieved from http://revslib.stanford.edu"
      end
    end
    context 'given fixture' do
      let(:pub_hash) { PubHash.new(case_study_pub_hash) }
      ##
      # Difference from our spec here is we don't add the optional "[Case study]." clarification string.
      # http://www.easybib.com/guides/citation-guides/how-do-i-cite-a/case-study/
      it 'creates a APA citation' do
        expect(pub_hash.to_apa_citation).to eq "Hill, L., Khanna, T., &amp; Stecker, E. A. (2008). <i>HCL Technologies</i>. Boston: Harvard Business Publishing."
      end
      ##
      # Difference from our spec here is we don't add the optional "Case study." clarification string.
      # http://www.easybib.com/guides/citation-guides/how-do-i-cite-a/case-study/
      it 'creates a Chicago citation' do
        expect(pub_hash.to_chicago_citation).to eq 'Hill, Linda, Tarun Khanna, and Emily A. Stecker. 2008. <i>HCL Technologies</i>. Boston: Harvard Business Publishing.'
      end
      ##
      # Difference from our spec here is we don't add the optional "Case study." clarification string.
      # http://www.easybib.com/guides/citation-guides/how-do-i-cite-a/case-study/
      it 'creates a MLA citation' do
        expect(pub_hash.to_mla_citation).to eq 'Hill, Linda, Tarun Khanna, and Emily A. Stecker. <i>HCL Technologies</i>. Boston: Harvard Business Publishing, 2008. Print.'
      end
    end
  end
  describe 'User submitted source records' do
    context 'book' do
      let(:pub_hash) { PubHash.new(JSON.parse(create(:book).source_data, symbolize_names: true)) }
      it 'creates a Chicago citation' do
        expect(pub_hash.to_chicago_citation).to eq 'Reed, Phillip J., and Jane Stanford. 2015. <i>This Is a Book Title</i>. Vol. 3. The Series Title. Stanford University Press.'
      end
      it 'creates a MLA citation' do
        expect(pub_hash.to_mla_citation).to eq 'Reed, Phillip J., and Jane Stanford. <i>This Is a Book Title</i>. vol. 3. Stanford University Press, 2015. Print. The Series Title.'
      end
      it 'creates a APA citation' do
        expect(pub_hash.to_apa_citation).to eq 'Reed, P. J., &amp; Stanford, J. (2015). <i>This is a book title</i> (Vol. 3). Stanford University Press.'
      end
    end
    context 'book chapter' do
      let(:pub_hash) { PubHash.new(JSON.parse(create(:book_chapter).source_data, symbolize_names: true)) }
      it 'creates a Chicago citation' do
        expect(pub_hash.to_chicago_citation).to eq "Hardy, Darren, Jack Reed, and Bess Sadler. 2016. <i>Geospatial Resource Discovery</i>. <i>Exploring Discovery: The Front Door to Your Library's Licensed and Digitized Content</i>. American Library Association Editions."
      end
      it 'creates a MLA citation' do
        expect(pub_hash.to_mla_citation).to eq "Hardy, Darren, Jack Reed, and Bess Sadler. <i>Geospatial Resource Discovery</i>. American Library Association Editions, 2016. Print."
      end
      it 'creates a APA citation' do
        expect(pub_hash.to_apa_citation).to eq "Hardy, D., Reed, J., &amp; Sadler, B. (2016). <i>Geospatial Resource Discovery</i>. <i>Exploring Discovery: The Front Door to Your Library's Licensed and Digitized Content</i> (pp. 47–62). American Library Association Editions."
      end
    end
    context 'conference proceeding' do
      let(:pub_hash) { PubHash.new(JSON.parse(create(:conference_proceeding).source_data, symbolize_names: true)) }
      it 'creates a Chicago citation' do
        expect(pub_hash.to_chicago_citation).to eq 'Reed, Jack. 2015. “Preservation and Discovery for GIS Data.” Esri.'
      end
      it 'creates a MLA citation' do
        expect(pub_hash.to_mla_citation).to eq 'Reed, Jack. “Preservation and Discovery for GIS Data.” 2015: n. pag. Print.'
      end
      it 'creates a APA citation' do
        expect(pub_hash.to_apa_citation).to eq 'Reed, J. (2015). Preservation and discovery for GIS data. Presented at the Esri User Conference, San Diego, California: Esri.'
      end
    end
    context 'conference proceeding without city' do
      let(:pub_hash) do
        h = JSON.parse(create(:conference_proceeding).source_data, symbolize_names: true)
        h[:conference][:location] = nil
        h[:conference][:city] = nil
        h[:conference][:statecountry] = 'California'
        PubHash.new(h)
      end
      it 'creates citation data for event-place' do
        expect(pub_hash.csl_doc).to include('event-place' => 'California')
      end
      it 'creates a APA citation' do
        expect(pub_hash.to_apa_citation).to eq 'Reed, J. (2015). Preservation and discovery for GIS data. Presented at the Esri User Conference, California: Esri.'
      end
    end
    context 'conference proceeding with city but no state' do
      let(:pub_hash) do
        h = JSON.parse(create(:conference_proceeding).source_data, symbolize_names: true)
        h[:conference][:location] = nil
        h[:conference][:city] = 'San Diego'
        h[:conference][:statecountry] = nil
        PubHash.new(h)
      end
      it 'creates citation data for event-place' do
        expect(pub_hash.csl_doc).to include('event-place' => 'San Diego')
      end
      it 'creates a APA citation' do
        expect(pub_hash.to_apa_citation).to eq 'Reed, J. (2015). Preservation and discovery for GIS data. Presented at the Esri User Conference, San Diego: Esri.'
      end
    end
    context 'conference proceeding with city and state' do
      let(:pub_hash) do
        h = conference_pub_in_journal_hash
        h[:conference][:location] = nil
        PubHash.new(h)
      end
      it 'has an event' do
        expect(pub_hash.csl_doc).to include('event' => 'The Big Conference',
                                            'event-place' => 'Knoxville,TN') # TODO: comma has no space after it
      end
    end
    context 'conference proceeding published in a journal and location' do
      let(:pub_hash) do
        h = conference_pub_in_journal_hash
        h[:conference][:city] = nil
        h[:conference][:statecountry] = nil
        PubHash.new(h)
      end
      it 'has a journal' do
        expect(pub_hash.csl_doc).to include('container-title' => 'Some Journal Name')
      end
      it 'has an event with location' do
        expect(pub_hash.csl_doc).to include('event' => 'The Big Conference',
                                            'event-place' => 'Knoxville, TN')
      end
    end
    context 'journal article' do
      let(:pub_hash) { PubHash.new(JSON.parse(create(:journal_article).source_data, symbolize_names: true)) }
      it 'creates a Chicago citation' do
        expect(pub_hash.to_chicago_citation).to eq 'Glover, Jeffrey B., Kelly Woodard, P. Jack Reed, and Johnny Waits. 2012. “The Flat Rock Cemetery Mapping Project:  A Case Study in Community Archaeology.” <i>Early Georgia</i> 40 (1). The Society for Georgia Archaeology.'
      end
      it 'creates a MLA citation' do
        expect(pub_hash.to_mla_citation).to eq 'Glover, Jeffrey B. et al. “The Flat Rock Cemetery Mapping Project:  A Case Study in Community Archaeology.” <i>Early Georgia</i> 40.1 (2012): n. pag. Print.'
      end
      it 'creates a APA citation' do
        expect(pub_hash.to_apa_citation).to eq 'Glover, J. B., Woodard, K., Reed, P. J., &amp; Waits, J. (2012). The Flat Rock Cemetery Mapping Project:  A Case Study in Community Archaeology. <i>Early Georgia</i>, <i>40</i>(1).'
      end
    end
  end
end
