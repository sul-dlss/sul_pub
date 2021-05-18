# frozen_string_literal: true

describe Orcid::Client do
  let(:subject) { described_class.new }

  describe '#fetch_works' do
    let(:works_response) { subject.fetch_works('https://orcid.org/0000-0003-1527-0030') }

    it 'retrieves works summary' do
      VCR.use_cassette('Orcid_Client/_fetch_works/retrieves works summary') do
        expect(works_response[:group].size).to eq(36)
      end
    end

    context 'when server returns 500' do
      it 'raises' do
        VCR.use_cassette('Orcid_Client/_fetch_works/raises') do
          expect { works_response }.to raise_error('ORCID.org API returned 500')
        end
      end
    end
  end

  describe '#add_work' do
    let(:work) do
      {
        title: {
          title: {
            value: 'Twitter Makes It Worse: Political Journalists, Gendered Echo Chambers, and the Amplification of Gender Bias'
          },
          subtitle: nil,
          "translated-title": nil
        },
        "journal-title": {
          value: 'The International Journal of Press/Politics'
        },
        "short-description": nil,
        citation: {
          "citation-type": 'bibtex',
          "citation-value": "@article{Usher_2018,\n\tdoi = {10.1177/1940161218781254},\n\turl = {https://doi.org/10.1177%2F1940161218781254},\n\tyear = 2018,\n\tmonth = {jun},\n\tpublisher = {{SAGE} Publications},\n\tvolume = {23},\n\tnumber = {3},\n\tpages = {324--344},\n\tauthor = {Nikki Usher and Jesse Holcomb and Justin Littman},\n\ttitle = {Twitter Makes It Worse: Political Journalists, Gendered Echo Chambers, and the Amplification of Gender Bias},\n\tjournal = {The International Journal of Press/Politics}\n}"
        },
        type: 'journal-article',
        "publication-date": {
          year: {
            value: '2018'
          },
          month: {
            value: '07'
          },
          day: {
            value: '24'
          }
        },
        "external-ids": {
          "external-id": [
            {
              "external-id-type": 'doi',
              "external-id-value": '10.1177/1940161218781254',
              "external-id-normalized": {
                value: '10.1177/1940161218781254',
                transient: true
              },
              "external-id-normalized-error": nil,
              "external-id-url": {
                value: 'https://doi.org/10.1177/1940161218781254'
              },
              "external-id-relationship": 'self'
            }
          ]
        },
        url: {
          value: 'https://doi.org/10.1177/1940161218781254'
        },
        contributors: {
          contributor: [
            {
              "contributor-orcid": nil,
              "credit-name": {
                value: 'Nikki Usher'
              },
              "contributor-email": nil,
              "contributor-attributes": {
                "contributor-sequence": nil,
                "contributor-role": 'author'
              }
            },
            {
              "contributor-orcid": nil,
              "credit-name": {
                value: 'Jesse Holcomb'
              },
              "contributor-email": nil,
              "contributor-attributes": {
                "contributor-sequence": nil,
                "contributor-role": 'author'
              }
            },
            {
              "contributor-orcid": nil,
              "credit-name": {
                value: 'Justin Littman'
              },
              "contributor-email": nil,
              "contributor-attributes": {
                "contributor-sequence": nil,
                "contributor-role": 'author'
              }
            }
          ]
        },
        "language-code": nil,
        country: nil
      }
    end

    let(:put_code) { subject.add_work('https://sandbox.orcid.org/0000-0003-3437-349X', work, 'FAKE29cb-194e-4bc3-8afg-99315b06be04') }

    context 'when creating work the first time' do
      it 'adds works' do
        VCR.use_cassette('Orcid_Client/_add_work/adds work') do
          expect(put_code).to eq('1250170')
        end
      end
    end

    context 'when work already exists' do
      it 'handles conflict' do
        VCR.use_cassette('Orcid_Client/_add_work/adds work again') do
          expect(put_code).to eq('1250170')
        end
      end
    end
  end
end
