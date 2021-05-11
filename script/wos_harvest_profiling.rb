# Usage
# RAILS_ENV=production bundle exec rails runner ./script/wos_harvest_profiling.rb > log/wos_harvest_profiling.txt

require 'ruby-prof'
RubyProf.start

authors = Author.where(active_in_cap: true, cap_import_enabled: true).limit(15)
WebOfScience.harvester.harvest(authors)

result = RubyProf.stop

# print a flat profile to text
printer = RubyProf::FlatPrinter.new(result)
printer.print($stdout)
