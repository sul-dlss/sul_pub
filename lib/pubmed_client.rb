class PubmedClient
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
        NotificationManager.handle_pubmed_pull_error(te, "Timeout error on call to pubmed api - #{Time.zone.now}")
        raise
      end
    rescue => e
      NotificationManager.handle_pubmed_pull_error(e, 'Problem with http call to pubmed api')
      raise
  end
end
