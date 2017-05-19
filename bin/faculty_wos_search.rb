# using Web of Science API (new)
$stdout.sync = true # flush output immediately

input_file='/Users/petucket/Downloads/rialto_sample.csv'
output_file='/Users/petucket/Downloads/rialto_results.csv'

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
       req.headers['Authorization'] = 'Basic U3RhbmZvcmRVX1NXOjJAIyRTdFVuaQ' 
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

def count_countries(result_xml_doc,countries_count,author_countries_count,organizations_count,author_organizations_count)
  begin
    puts "........collecting pubs"
    pubs = Nokogiri::XML(result_xml_doc.xpath("//records")[0].content).remove_namespaces!.xpath('//records/REC')
    puts "........looking for countries"
    countries =  pubs.search('addresses//country').map {|address| address.content.titleize}
    puts "........looking for organizations"
    organizations =  pubs.search("addresses//organization[@pref='Y']").map {|organization| organization.content}
    puts "........enumerating countries"
    countries.each do |country| 
      countries_count[country] += 1
      author_countries_count[country] += 1
    end
    puts ".......enumerating organizations"
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
total_names = names.size
puts "#{total_names} total unique names found"

sid = authenticate
institutions = ["Stanford University"] # could be an array of institutions

countries_count = Hash.new(0)
author_countries_count = Hash.new
organizations_count = Hash.new(0)
author_organizations_count = Hash.new

total_pubs = 0 
max_records = 100 # this is the maximum number that can be returned in single query by WoS
names.each_with_index do |name,index|
  next if name.blank?
  
  puts "#{index+1} of #{total_names}: searching on #{name}"
  author_countries_count[name] = Hash.new(0)
  author_organizations_count[name] = Hash.new(0)
  num_retrieved = 0
  query = name_query(name)
  # run the first query
  body = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:woksearch=\"http://woksearch.v3.wokmws.thomsonreuters.com\"><soapenv:Header/><soapenv:Body><woksearch:search><queryParameters><databaseId>WOS</databaseId><userQuery>AU=(#{query}) AND OG=(#{institutions.join(' OR ')})</userQuery><timeSpan><begin>1970-01-01</begin><end>2017-05-01</end></timeSpan><queryLanguage>en</queryLanguage></queryParameters><retrieveParameters><firstRecord>1</firstRecord><count>#{max_records}</count><option><key>RecordIDs</key><value>On</value></option><option><key>targetNamespace</key><value>http://scientific.thomsonreuters.com/schema/wok5.4/public/FullRecord</value></option></retrieveParameters></woksearch:search></soapenv:Body></soapenv:Envelope>"
  result_xml_doc = run_search(body,sid)
  query_id = result_xml_doc.at_xpath('//queryId').content
  num_records = result_xml_doc.at_xpath('//recordsFound').content.to_i
  puts "...found #{num_records} pubs using #{query}"

  num_pubs = count_countries(result_xml_doc,countries_count,author_countries_count[name],organizations_count,author_organizations_count[name])
  num_retrieved += num_pubs
  
  while (num_retrieved < num_records && num_pubs != 0) do # we have more to go
    next_record = num_retrieved + 1
    puts "..... fetching next batch starting at #{next_record}"
    body = "<soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\"><soap:Body><ns2:retrieve xmlns:ns2=\"http://woksearch.v3.wokmws.thomsonreuters.com\"><queryId>#{query_id}</queryId><retrieveParameters><firstRecord>#{next_record}</firstRecord><count>100</count></retrieveParameters></ns2:retrieve></soap:Body></soap:Envelope>"
    result_xml_doc = run_search(body,sid)
    num_pubs = count_countries(result_xml_doc,countries_count,author_countries_count[name],organizations_count,author_organizations_count[name])
    num_retrieved += num_pubs
  end

  puts author_countries_count[name]
  puts author_organizations_count[name]
  puts 
  total_pubs += num_records
  
end

puts 
puts "Total pubs analzyed: #{total_pubs}"
puts
sorted_countries_count = countries_count.sort_by{ |k, v| v }.reverse.to_h 
sorted_organizations_count = organizations_count.sort_by{ |k, v| v }.reverse.to_h 

puts sorted_countries_count
puts sorted_organizations_count

CSV.open(output_file, "wb") do |csv|
  csv << ["Totals",total_pubs]
  csv << sorted_countries_count.map { |key,value| key }
  csv << sorted_countries_count.map { |key,value| value }
  csv << sorted_organizations_count.map { |key,value| key }
  csv << sorted_organizations_count.map { |key,value| value }
  names.each do |name|
    next if name.blank?
    csv << []
    csv << [name]
    sorted_author_countries_count = author_countries_count[name].sort_by{ |k, v| v }.reverse.to_h 
    sorted_author_organizations_count = author_organizations_count[name].sort_by{ |k, v| v }.reverse.to_h 
    csv << sorted_author_countries_count.map {|key,value| key }
    csv << sorted_author_countries_count.map {|key,value| value }
    csv << sorted_author_organizations_count.map {|key,value| key }
    csv << sorted_author_organizations_count.map {|key,value| value }
  end
end
