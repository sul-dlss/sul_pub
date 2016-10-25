class PubmedClient
  # Fetch a single publication and parse the response
  def self.working?
    Nokogiri::XML(new.fetch_records_for_pmid_list('22895186')).present?
  end

  def fetch_records_for_pmid_list(pmids)
    pmid_list = Array(pmids)
    pmidValuesForPost = pmid_list.collect { |pmid| "&id=#{pmid}" }.join
    timeout_retries ||= 3
    timeout_period ||= 500
    conn = Faraday.new(url: Settings.PUBMED.BASE_URI) do |faraday|
      faraday.request :retry, max: timeout_retries,
        interval: 0.5,
        interval_randomness: 0.5,
        backoff_factor: 2
      faraday.adapter :httpclient
    end
    conn.options.timeout = timeout_period
    conn.options.open_timeout = 10

    response = conn.send(:post) do |req|
      req.url Settings.PUBMED.FETCH_PATH
      req.body = pmidValuesForPost
    end

    response.body
  rescue => e
    NotificationManager.handle_pubmed_pull_error(e, 'Problem with http call to pubmed api')
    raise
  end
end
