class PubmedClient
  # Fetch a single publication and parse and ensure we have a correct response.
  # We check in steps that the response is XML and it includes the correct content.
  def self.working?
    response = new.fetch_records_for_pmid_list('22895186')
    response.is_a?(String) &&
      response.include?('<PubmedArticleSet>') &&
      (doc = Nokogiri::XML(response)).is_a?(Nokogiri::XML::Document) &&
      doc.at_xpath('/PubmedArticleSet/PubmedArticle/MedlineCitation/PMID/text()').to_s == '22895186' &&
      doc.at_xpath('//LastName[text()="Hardy"]').is_a?(Nokogiri::XML::Element)
  end

  # @param [String, Array<String>] pmids PubMed ID or IDs
  # @return [String] HTTP response body
  def fetch_records_for_pmid_list(pmids)
    pmid_list = Array(pmids)
    pmidValuesForPost = pmid_list.collect { |pmid| "&id=#{pmid}" }.join
    response = conn.post do |req|
      req.url Settings.PUBMED.FETCH_PATH
      req.body = pmidValuesForPost
    end
    response.body
  rescue StandardError => e
    NotificationManager.error(e, "#{e.class.name} during PubMed Fetch API call", self)
    raise
  end

  private

    # Use Settings.PUBMED.BASE_URI for connecting to the Pubmed API
    # @return [Faraday::Connection]
    def conn
      @conn ||= begin
        timeout_retries = 3
        timeout_period = 500
        conn = Faraday.new(url: Settings.PUBMED.BASE_URI) do |faraday|
          faraday.request :retry, max: timeout_retries,
                          interval: 0.5,
                          interval_randomness: 0.5,
                          backoff_factor: 2
          faraday.adapter :httpclient
        end
        conn.options.timeout = timeout_period
        conn.options.open_timeout = 10
        # need to set the user agent specifically since NIH is blocking the default Faraday user agent as of 1/8/2019 - Peter Mangiafico
        conn.headers[:user_agent] = 'stanford-library-sul-pub'
        conn
      end
    end

end
