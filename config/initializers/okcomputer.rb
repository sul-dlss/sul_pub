require 'okcomputer'

OkComputer.mount_at = 'status' # use /status or /status/all or /status/<name-of-check>
OkComputer.check_in_parallel = true

# Simple echo of the VERSION file
class VersionCheck < OkComputer::AppVersionCheck
  def version
    File.read(Rails.root.join('VERSION')).chomp
  rescue Errno::ENOENT
    raise UnknownRevision
  end
end
OkComputer::Registry.register 'version', VersionCheck.new

class DelegateCheck < OkComputer::Check
  attr_reader :delegate
  def initialize(delegate)
    @delegate = delegate
  end
  def check
    if delegate.working?
      mark_message 'working'
    else
      mark_failure
      mark_message 'not working'
      Honeybadger.notify(RuntimeError.new("#{delegate.name} is not working"))
    end
  rescue => e
    mark_failure
    mark_message "#{e.class.name} received: #{e.message}"
    Honeybadger.notify(e)
  end
end

# delegate to the clients to see if they are working
[
  CapHttpClient,
  PubmedClient,
  ScienceWireClient
].each do |klass|
  OkComputer::Registry.register "external-#{klass.name}", DelegateCheck.new(klass)
end

# check models to see if at least they have some data
class TablesHaveDataCheck < OkComputer::Check
  def check
    msg = ""
    [
      Author,
      BatchUploadedSourceRecord,
      Contribution,
      Publication,
      PublicationIdentifier,
      PubmedSourceRecord,
      SciencewireSourceRecord,
      UserSubmittedSourceRecord
    ].each do |klass|
      begin
        # has at least one record and use select(:id) to avoid returning all data
        if klass.select(:id).first!.present?
          msg += "#{klass.name} has data. "
        else
          mark_failure
          msg += "#{klass.name} has no data. "
        end
      rescue ActiveRecord::RecordNotFound
        mark_failure
        msg += "#{klass.name} has no data. "
      rescue => e
        mark_failure
        msg += "#{e.class.name} received: #{e.message}. "
      end
    end
    mark_message msg
  end
end
OkComputer::Registry.register "feature-tables-have-data", TablesHaveDataCheck.new
