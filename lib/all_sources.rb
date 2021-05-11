# All Sources harvesting utilities
module AllSources

  # @return [AllSources::Harvester]
  def self.harvester
    @@harvester ||= AllSources::Harvester.new
  end

  def self.logger
    @@logger ||= Logger.new(Settings.HARVESTER.LOG)
  end

end
