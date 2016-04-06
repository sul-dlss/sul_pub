Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  h.check :version do |status|
    status.ok(IO.read(Rails.root.join('VERSION')).strip)
  end

  # delegate to the client to see if they are working
  [
    CapHttpClient,
    PubmedClient,
    ScienceWireClient
  ].each do |klass|
    h.check klass.to_s.to_sym do |status|
      fail 'not working' unless klass.working?
      status.ok('working')
    end
  end

  # check models to see if at least they have some data
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
    h.check klass.to_s.to_sym do |status|
      # has at least one record and use select(:id) to avoid returning all data
      fail 'no data' unless klass.select(:id).first!.present?
      status.ok('has data')
    end
  end
end
