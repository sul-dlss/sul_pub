# frozen_string_literal: true

## March 2017
## This is a custom report produced for the Department of Pyschiatry admin.  It takes in a CSV list of faculty names
##   in a single column (labled "author"), and sunet if available in a second column.  Example data is shown below.

## Note that it only productions citation counts for publications harvested from sciencewire (so it will not work with WoS records)
##
## It produces an output CSV with the following columns:

## "Author", "All Publications", "Approved Publications", "Times Cited", "Times Cited (exclude self)"

## This includes counts of all publications, approved publications, and times cited information derived from SW records.

## To run, put the input CSV file on the server, specify the "input file" and "output file" full path in the script below
##   and run with
## RAILS_ENV=production bundle exec rails runner script/faculty_citation_report.rb

## Example CSV input file:
## author,sunet
# #"LastName,FirstName",
# #"LastName,FirstName Middle Initial",
# #"AnotherLast,Another First",sunetIDhere_if_available

if Settings.WOS.enabled
  puts '******* WARNING!  WoS API is enabled, which makes this report unreliable for the number of times cited.  ' \
       'Publication counts will still be correct. ******'
end

def get_contributions_for_sunet(sunetid)
  a = Author.where(sunetid:)
  all_contributions = 0
  approved_contributions = 0
  citations = 0
  citations_exclude_self = 0
  a.each do |author|
    all_contributions += author.contributions.size
    approved_contributions += author.contributions.where(status: 'approved').size
    author.publications.each do |pub|
      citations += pub.pub_hash[:timescited_sw_retricted].to_i
      citations_exclude_self += pub.pub_hash[:timenotselfcited_sw].to_i
    end
  end
  [all_contributions, approved_contributions, citations, citations_exclude_self]
end

def only_one_sunet?(authors)
  authors.map(&:sunetid).uniq.size == 1
end

def citation_search(input_file, output_file)
  users = CSV.new(File.new(input_file), headers: true, header_converters: :symbol,
                                        converters: [:all]).to_a.map(&:to_hash)

  CSV.open(output_file, 'wb') do |csv|
    csv << ['Author', 'All Publications', 'Approved Publications', 'Times Cited', 'Times Cited (exclude self)']
    users.each do |user|
      name = user[:author].split(',')
      sunet = user[:sunet]

      last_name = name[0]
      first_middle = name[1].split
      first_name = first_middle[0].tr('_', ' ').strip
      middle_name = first_middle.size > 1 ? first_middle[1].strip : ''

      if sunet.blank? # no sunet provided in the input
        authors = Author.where(official_last_name: last_name, official_first_name: first_name,
                               official_middle_name: middle_name, active_in_cap: true).where('sunetid is not null AND sunetid != ""')
        if authors.empty?
          authors = Author.where(official_last_name: last_name, official_first_name: first_name,
                                 active_in_cap: true).where('sunetid is not null AND sunetid != ""')
        end
      else
        authors = Author.where(sunetid: sunet.strip)
      end
      if authors.empty? # still no authors found
        error = '**************** NOT FOUND ******************'
        puts "\"#{user[:author]}\",#{error}"
        csv << [user[:author], error]
      elsif authors.size == 1 || only_one_sunet?(authors) # only one author found or more than one with same sunet, run co
        all_contributions, approved_contributions, citations, citations_exclude_self = get_contributions_for_sunet(authors[0].sunetid)
        puts "\"#{user[:author]}\",\"#{all_contributions}\",\"#{approved_contributions}\",\"#{citations}\",\"#{citations_exclude_self}\""
        csv << [user[:author], all_contributions, approved_contributions, citations, citations_exclude_self]
      else # more than one author that cannot be disambiguated
        error = "**************** MORE THAN ONE SUNET FOUND: #{authors.map(&:sunetid).join(',')}******************"
        puts "\"#{user[:author]}\",#{error}"
        csv << [user[:author], error]
      end
    end
    nil
  end
end

input_file = '/tmp/psych_faculty.csv' # format of input file is two columns, first has a header of "author", second has a header of "sunet".
# author column is LastName,FirstName Middle Name
# sunet column is sunet
output_file = '/tmp/report.csv' # output report

citation_search(input_file, output_file)
