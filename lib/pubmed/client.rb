module Pubmed
  class Client
    # @param [String, Array<String>] pmids PubMed ID or IDs
    # @return [String] HTTP response body
    def fetch_records_for_pmid_list(pmids)
      pmid_list = Array(pmids)
      pmidValuesForPost = pmid_list.collect { |pmid| "&id=#{pmid}" }.join
      response = conn.post do |req|
        req.url "#{Settings.PUBMED.FETCH_PATH}&api_key=#{Settings.PUBMED.API_KEY}"
        req.body = pmidValuesForPost
      end
      response.body
    rescue StandardError => e
      NotificationManager.error(e, "#{e.class.name} during PubMed Fetch API call", self)
      raise
    end

    # @param [String] term to search on, excluding term=
    # @return [String] HTTP response body
    def search(term, addl_args = nil)
      response = conn.post do |req|
        req.url url(addl_args)
        req.body = "term=#{term}"
      end
      response.body
    rescue StandardError => e
      NotificationManager.error(e, "#{e.class.name} during PubMed Search API call", self)
      raise
    end

    private

      def url(addl_args)
        url = "#{Settings.PUBMED.SEARCH_PATH}&retmax=#{Settings.PUBMED.max_publications_per_author}&api_key=#{Settings.PUBMED.API_KEY}"
        if addl_args
          url << '&' unless addl_args[0] == '&'
          url << addl_args
        end
        url
      end

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
end
