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

  def fetch_records_for_pmid_list(pmids)
    pmid_list = Array(pmids)
    pmidValuesForPost = pmid_list.collect { |pmid| "&id=#{pmid}" }.join
    timeout_retries ||= 3
    timeout_period ||= 500
    http = Net::HTTP.new(Settings.PUBMED.HOST)
    http.read_timeout = timeout_period
    request = Net::HTTP::Post.new(Settings.PUBMED.FETCH_PATH)
    request.body = pmidValuesForPost
    # http.start
    the_incoming_xml = http.request(request).body
    # http.finish
    the_incoming_xml

    rescue Timeout::Error => te
      timeout_retries -= 1
      if timeout_retries > 0
        # increase timeout
        timeout_period = + 500
        retry
      else
        NotificationManager.error(te, 'Timeout::Error during PubMed Fetch API call', self)
        raise
      end
    rescue => e
      NotificationManager.error(e, "#{e.class.name} during PubMed Fetch API call", self)
      raise
  end
end
