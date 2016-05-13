namespace :pubmed do
  def client
    @client ||= PubmedClient.new
  end

  desc 'Retrieve and print a single publication by PubMed-ID'
  task :publication, [:pmid] => :environment do |_t, args|
    fail "pmid argument is required." unless args[:pmid].present?
    pmids = [args[:pmid]]
    doc = client.fetch_records_for_pmid_list(pmids)
    puts doc # XML document
  end
end
