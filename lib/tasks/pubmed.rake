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

  desc 'Harvest using a text file with a list of publications by PubmedID for the supplied cap_profile_id'
  task :pmid_profile_id_import, [:path_to_report,:cap_profile_id] => :environment do |_t, args|
    lines = IO.readlines args[:path_to_report]
    author = Author.find_by_cap_profile_id(args[:cap_profile_id])

    puts "Cap_profile_id #{args[:cap_profile_id]} is #{author.first_name} #{author.last_name}"
    total_pub_count=author.contributions.size
    new_pub_count=author.contributions.where(:status=>'new').size
    approved_pub_count=author.contributions.where(:status=>'approved').size
    puts "total publications: #{total_pub_count}"
    puts "total new publications: #{new_pub_count}"
    puts "total accepted publications: #{approved_pub_count}"
    puts "attempting to harvest #{lines.count} new publications by pubmedID"
    puts

    harvester=ScienceWireHarvester.new
    lines.each do |line|
      pmid=line.chomp
      puts "working on #{pmid}..."
      pub=Publication.find_or_create_by_pmid(pmid)
      harvester.add_contribution_for_harvest_suggestion(author,pub)
      pub.add_all_db_contributions_to_my_pub_hash
      pub.save
    end

    author.reload
    new_pub_count=author.contributions.where(:status=>'new').size - new_pub_count
    puts ""
    puts "added publications: #{new_pub_count}"

  end
end
