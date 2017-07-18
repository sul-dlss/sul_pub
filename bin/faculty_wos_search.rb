# using Web of Science API (new)
$stdout.sync = true # flush output immediately

# input file is CSV format with name in first column in "Last, First Middle" format.
#  the CSV file should include a header row as well, though the header names don't matter
#  extra columns are fine
input_file='/Users/peter/Downloads/rialto_sample.csv'
output_file='/Users/peter/Downloads/rialto_sample_results.csv'
limit = nil # limit the number of people searched regardless of input size, set to nil or blank for no limits
start_date = "1970-01-01" # limit the start date when searching for publications, format: YYYY-MM-DD
end_date = Time.now.strftime("%Y-%m-%d") # the end date defaults to today

# an array of organizations to restrict the results to (set to nil for no restrictions)
restrict_to_organizations = ['Stanford','Stanford University','UCSF','University of California San Francisco','UCSF School of Medicine','University of California, San Francisco','UCB','Berkeley','University of California Berkeley','UC Berkeley']
search_countries = false # set to false to skip country enumeration for faster results
institutions = ["Stanford University"] # search pubs for names are restricted -- could be an array of institutions

require 'rubygems'
# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
require 'rails'
require 'csv'
require 'faraday'
require 'nokogiri'

def web_of_science_conn
  @conn ||= Faraday.new(:url => 'http://search.webofknowledge.com')
end

def authenticate
  body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:auth="http://auth.cxf.wokmws.thomsonreuters.com"><soapenv:Header/><soapenv:Body><auth:authenticate/></soapenv:Body></soapenv:Envelope>'
  auth = web_of_science_conn.post do |req|
       req.url '/esti/wokmws/ws/WOKMWSAuthenticate'
       req.headers['Content-Type'] = 'application/xml'
       req.headers['Authorization'] = 'Basic X'
       req.body = body
  end
  auth_xml_doc  = Nokogiri::XML(auth.body).remove_namespaces!
  auth_xml_doc.xpath('//authenticateResponse//return')[0].content
end

def run_search(body,sid)
  begin
    response = web_of_science_conn.post do |req|
       req.url '/esti/wokmws/ws/WokSearch'
       req.headers['Content-Type'] = 'application/xml'
       req.headers['Cookie'] = "SID=\"#{sid}\""
       req.body = body
    end
    Nokogiri::XML(response.body).remove_namespaces!
  rescue
    Nokogiri::XML("<xml/>")
  end
end

def name_query(name)
  split_name=name.split(',')
  last_name = split_name[0]
  first_middle_name = split_name[1]
  first_name = first_middle_name.split(' ')[0]
  middle_name = first_middle_name.split(' ')[1]
  name_query = "#{last_name} #{first_name} OR #{last_name} #{first_name[0]}"
  name_query += " OR #{last_name} #{first_name[0]}#{middle_name[0]} OR #{last_name} #{first_name} #{middle_name[0]}" unless middle_name.blank?
  name_query
end

def enumerate_results(result_xml_doc,countries_count,author_countries_count,organizations_count,author_organizations_count,search_countries,restrict_to_organizations)
  begin

    puts "........collecting pubs"
    pubs = Nokogiri::XML(result_xml_doc.xpath("//records")[0].content).remove_namespaces!.xpath('//records/REC')

    if search_countries
      puts "........looking for countries"
      countries =  pubs.search('addresses//country').map {|address| address.content.titleize}
    end

    puts "........looking for organizations"
    organizations =  pubs.search("addresses//organization[@pref='Y']").map do |organization|
      org_name = organization.content
      unless restrict_to_organizations.blank?
        org_name if restrict_to_organizations.include?(org_name)
      else
        org_name
      end
    end
    organizations.reject!(&:blank?)

    if search_countries
      puts "........enumerating countries"
      countries.each do |country|
        countries_count[country] += 1
        author_countries_count[country] += 1
      end
    end

    puts "........enumerating organizations"
    organizations.each do |organization|
      organizations_count[organization] += 1
      author_organizations_count[organization] += 1
    end
    return pubs.size

  rescue
    return 0
  end

end

puts "Reading #{input_file}"
names = []
CSV.foreach(input_file,:headers=>true) do |row|
  names << row[0]
end
puts "#{names.size} total names found"

names.uniq!
puts "#{names.size} total unique names found"

unless limit.blank?
  puts "limit of #{limit} applied"
  names = names[0..limit-1]
end
total_names = names.size
puts "#{total_names} total names will be operated on"

sid = authenticate

countries_count = Hash.new(0)
author_countries_count = Hash.new
organizations_count = Hash.new(0)
author_organizations_count = Hash.new

total_pubs = 0
max_records = 100 # this is the maximum number that can be returned in single query by WoS
max_runs_per_person = 30 # set some maximum number of runs we will attempt to fetch records for any given person (thereby limiting the max number of pubs to max_records * max_runs_per_person)

names.each_with_index do |name,index|
  next if name.blank?

  csv_output = CSV.open(output_file, "ab")

  puts "#{index+1} of #{total_names}: searching on #{name}"
  author_countries_count[name] = Hash.new(0)
  author_organizations_count[name] = Hash.new(0)
  num_retrieved = 0
  num_runs = 0
  query = name_query(name)
  # run the first query
  body = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:woksearch=\"http://woksearch.v3.wokmws.thomsonreuters.com\"><soapenv:Header/><soapenv:Body><woksearch:search><queryParameters><databaseId>WOS</databaseId><userQuery>AU=(#{query}) AND OG=(#{institutions.join(' OR ')})</userQuery><timeSpan><begin>#{start_date}</begin><end>#{end_date}</end></timeSpan><queryLanguage>en</queryLanguage></queryParameters><retrieveParameters><firstRecord>1</firstRecord><count>#{max_records}</count><option><key>RecordIDs</key><value>On</value></option><option><key>targetNamespace</key><value>http://scientific.thomsonreuters.com/schema/wok5.4/public/FullRecord</value></option></retrieveParameters></woksearch:search></soapenv:Body></soapenv:Envelope>"
  result_xml_doc = run_search(body,sid)
  query_id_node = result_xml_doc.at_xpath('//queryId')
  query_id = query_id_node.nil? ? "" : query_id_node.content
  num_records_node = result_xml_doc.at_xpath('//recordsFound')
  num_records = num_records_node.nil? ? 0 : num_records_node.content.to_i
  puts "...found #{num_records} pubs using #{query}"

  if num_records > 0
    num_pubs = enumerate_results(result_xml_doc,countries_count,author_countries_count[name],organizations_count,author_organizations_count[name],search_countries,restrict_to_organizations)
    num_retrieved += num_pubs
    while (num_retrieved < num_records && num_pubs != 0 && num_runs < max_runs_per_person) do # we have more to go
      next_record = num_retrieved + 1
      puts "..... fetching next batch starting at #{next_record}"
      body = "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><ns2:retrieve xmlns:ns2=\"http://woksearch.v3.wokmws.thomsonreuters.com\"><queryId>#{query_id}</queryId><retrieveParameters><firstRecord>#{next_record}</firstRecord><count>100</count></retrieveParameters></ns2:retrieve></soap:Body></soap:Envelope>"
      result_xml_doc = run_search(body,sid)
      num_pubs = enumerate_results(result_xml_doc,countries_count,author_countries_count[name],organizations_count,author_organizations_count[name],search_countries,restrict_to_organizations)
      num_retrieved += num_pubs
      num_runs+=1
    end
  end

  puts author_countries_count[name] if search_countries

  puts author_organizations_count[name]
  puts
  total_pubs += num_records

  csv_output << []
  csv_output << [name,num_records]
  sorted_author_countries_count = author_countries_count[name].sort_by{ |k, v| v }.reverse.to_h
  sorted_author_organizations_count = author_organizations_count[name].sort_by{ |k, v| v }.reverse.to_h
  if search_countries
    csv_output << sorted_author_countries_count.map {|key,value| key }
    csv_output << sorted_author_countries_count.map {|key,value| value }
  end
  csv_output << sorted_author_organizations_count.map {|key,value| key }
  csv_output << sorted_author_organizations_count.map {|key,value| value }

  csv_output.close

end

puts
puts "Total pubs analzyed: #{total_pubs}"
puts
sorted_countries_count = countries_count.sort_by{ |k, v| v }.reverse.to_h if search_countries
sorted_organizations_count = organizations_count.sort_by{ |k, v| v }.reverse.to_h

puts sorted_countries_count if search_countries
puts sorted_organizations_count

csv_output = CSV.open(output_file, "ab")
csv_output << []

csv_output << ["Totals",total_pubs]
if search_countries
  csv_output << sorted_countries_count.map { |key,value| key }
  csv_output << sorted_countries_count.map { |key,value| value }
end
csv_output << sorted_organizations_count.map { |key,value| key }
csv_output << sorted_organizations_count.map { |key,value| value }

csv_output.close
