describe 'Smart query', 'data-integration': true do
  let(:client) do
    ScienceWire::Client.new(
      license_id: Settings.SCIENCEWIRE.LICENSE_ID,
      host: Settings.SCIENCEWIRE.HOST
    )
  end

  # Retrieve PublicationItem array in JSON
  def get_pubs(suggestions)
    pub_ids = suggestions.join(',')
    JSON.parse(client.publication_items(pub_ids, 'json'))
  end

  def check_suggestions(suggestions)
    expect(suggestions.count).to be > 0
    pub_id_intersection = suggestions.to_set.intersection(known_publications || [])
    pubs = get_pubs(suggestions)
    # Try to find some known DOI in the results
    doi_pubs = pubs.select do |pub|
      known_doi.include? pub['DOI']
    end
    # Try to find publications with known keywords in the results
    keyword_pubs = pubs.select do |pub|
      keywords = pub['KeywordList'].split('|').map(&:downcase).to_set
      known_keywords.intersection(keywords).count > 0
    end
    # Try to find some known subjects in the results
    subject_pubs = pubs.select do |pub|
      subjects = pub['PublicationSubjectCategoryList'].split('|').map(&:downcase).to_set
      known_subjects.intersection(subjects).count > 0
    end
    # Consider it a general success if any PubId, DOI, keywords or subjects match the publications
    anything = pub_id_intersection.count + doi_pubs.count + keyword_pubs.count + subject_pubs.count
    expect(anything).to be > 0
  end

  shared_examples 'it returns suggestions without seeds' do
    let(:seeds) { [] }
    it '(without email)' do
      # The API requires either an email or a seed list.  It should respond with
      # a 422 HTTP status code (unprocessable entity), but it actually
      # returns a 500 HTTP status.
      expect do
        client.id_suggestions(
          ScienceWire::AuthorAttributes.new(
            Agent::AuthorName.new(ln, fn, mn), '', seeds
          )
        )
      end.to raise_error(Faraday::ClientError)
    end
    it '(name with email)' do
      suggestions = client.id_suggestions(
        ScienceWire::AuthorAttributes.new(
          Agent::AuthorName.new(ln, fn, mn), email, seeds
        )
      )
      check_suggestions(suggestions)
    end
    # it '(name with email & institution)' do
    #   # Currently the institution is hard-coded as the address for Stanford,
    #   # That is a mistake for authors with alt-name data that
    #   # contain an email from an alternate institution, if we also had
    #   # an institution name (and address).  So, until that is changed, this
    #   # query should return the same results as the one without an institution.
    #   # See github issues 277, 286, 287.
    #   suggestions = client.id_suggestions(
    #     ScienceWire::AuthorAttributes.new(ln, fn, mn, email, seeds, institution)
    #   )
    #   check_suggestions(suggestions)
    # end
  end

  context 'using Darren Lee Weber' do
    let(:fn) { 'Darren' }
    let(:mn) { 'Lee' }
    let(:ln) { 'Weber' }
    let(:known_publications) do
      Set.new([9_739_185, 7_341_163, 43_179_644, 2_130_286])
    end
    let(:known_keywords) do
      [
        'EVENT-RELATED POTENTIALS', 'ERPS', 'BRAIN POTENTIALS', 'P300',
        'electrophysiology', 'ELECTROMAGNETIC TOMOGRAPHY', 'topographic brain mapping',
        'ATTENTION', 'SHORT-TERM-MEMORY', 'cognition', 'vision',
        'PREFRONTAL CORTEX',
        'PSYCHIATRIC-SYMPTOMS', 'PTSD', 'anxiety',
      ].map(&:downcase).to_set
    end
    let(:known_subjects) do
      [
        'Clinical Neurology', 'Neuroimaging', 'Neurosciences', 'Psychiatry', 'Psychology, Clinical'
      ].map(&:downcase).to_set
    end
    let(:known_doi) do
      Set.new(['10.1016/j.pscychresns.2005.07.003'])
    end

    context 'Flinders' do
      let(:email) { 'darren.weber_#at#_flinders.edu.au'.gsub('_#at#_', '@') }
      let(:institution) { 'Flinders University of South Australia' }
      # Cognitive Neuroscience Laboratory, The Flinders University of South Australia, GPO Box 2100, Adelaide, SA 5001, Australia
      it_behaves_like 'it returns suggestions without seeds'
    end
    context 'UCSF' do
      let(:email) { 'darren.weber_#at#_radiology.ucsf.edu'.gsub('_#at#_', '@') }
      let(:institution) { 'University of California, San Francisco' }
      # UCSF Department of Radiology, 185 Berry Street, Suite 350, San Francisco, CA 94107, USA.
      it_behaves_like 'it returns suggestions without seeds'
    end
  end

  context 'with email address only' do
    context 'using Darren Hardy' do
      it 'returns suggestions' do
        known_confirmed_publications = [64_367_696]
        suggestions = client.id_suggestions(
          ScienceWire::AuthorAttributes.new(
            Agent::AuthorName.new(
              'Hardy', 'Darren', ''
            ), 'darren.hardy@stanford.edu', ''
          )
        )
        expect(suggestions.count).to be >= 1 # only 1 is correct
        expect(suggestions).to include(*known_confirmed_publications)
      end
      it 'returns suggestions' do
        known_confirmed_publications = [64_367_696]
        suggestions = client.id_suggestions(
          ScienceWire::AuthorAttributes.new(
            Agent::AuthorName.new(
              'Hardy', 'Darren', ''
            ), 'drh@stanford.edu', ''
          )
        )
        expect(suggestions.count).to be >= 1 # only 1 in correct
        expect(suggestions).to include(*known_confirmed_publications)
      end
      it 'returns suggestions' do
        known_confirmed_publications = [61_063_453, 64_367_696, 67_380_595]
        suggestions = client.id_suggestions(
          ScienceWire::AuthorAttributes.new(
            Agent::AuthorName.new(
              'Hardy', 'Darren', ''
            ), 'dhardy@bren.ucsb.edu', ''
          )
        )
        expect(suggestions.count).to be >= 3 # only 3 are correct
        expect(suggestions).to include(*known_confirmed_publications)
      end
    end
    context 'using Jack Reed' do
      it 'returns suggestions' do
        known_confirmed_publications = [60_931_052]
        suggestions = client.id_suggestions(
          ScienceWire::AuthorAttributes.new(
            Agent::AuthorName.new(
              'Reed', 'P', ''
            ), 'preed2@gsu.edu', ''
          )
        )
        expect(suggestions.count).to be >= 24 #2016.05.26
        expect(suggestions).to include(*known_confirmed_publications)
      end
      it 'returns suggestions' do
        known_confirmed_publications = [69_178_421]
        suggestions = client.id_suggestions(
          ScienceWire::AuthorAttributes.new(
            Agent::AuthorName.new(
              'Reed', 'J', ''
            ), 'preed2@gsu.edu', ''
          )
        )
        expect(suggestions.count).to be >= 68
        expect(suggestions).to include(*known_confirmed_publications)
      end
    end
  end
end
