
namespace :sul do
  desc 'rebuild authorship for selected pubs'
  task update_contribs_in_hash: :environment do
    #  publications = Publication.arel_table
    #	Publication.where(publications[:pub_hash].
    #    	matches("%okogiri%")).
    #    	each {|publication| publication.rebuild_pub_hash }
    Publication.find_each(&:rebuild_authorship)
  end

  desc 'rebuild authorship for selected pubs'
  task rebuild_bad_hashes: :environment do
    publications = Publication.arel_table
    Publication.where(publications[:pub_hash]
        .matches('%okogiri%'))
      .each(&:rebuild_pub_hash)
    # Publication.find_each {|pub| pub.rebuild_authorship }
  end

  desc 'check external services'
  task :check_external_services, [:server] => :environment do |_t, args|
    conn = Faraday.new(:url=>args[:server])
    external_checks=%w{external-CapHttpClient external-ScienceWireClient external-PubmedClient}
    external_checks.each do |check_name|
      response = conn.get "/status/#{check_name}"
      puts "#{Time.now}: #{check_name}: #{response.status} - #{response.body}"
    end
  end
end
