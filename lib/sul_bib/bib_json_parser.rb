module SulBib
  module BibJSONParser
    def self.call(object, env)
      {:pub_hash => JSON.parse(object)}
    end
  end
end