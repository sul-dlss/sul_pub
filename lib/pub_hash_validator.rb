# frozen_string_literal: true

require 'json_schemer'
require 'yaml'

# Validates a pub_hash against JSON schema.
class PubHashValidator
  @@schemer = JSONSchemer.schema(YAML.safe_load(File.read(Rails.root.join('pub_hash_schema.yml'))))

  # @param [Hash] pub_hash
  # @return [Boolean] true if valid
  def self.valid?(pub_hash)
    @@schemer.valid?(pub_hash.with_indifferent_access)
  end

  # @param [Hash] pub_hash
  # @return [Array<String>] errors
  def self.validate(pub_hash)
    @@schemer.validate(pub_hash.with_indifferent_access).map do |error|
      if error.key?('details')
        "Invalid with details: #{error['details']}"
      else
        "#{error['data_pointer']} with value #{error['data']} is invalid for schema: #{error['schema_pointer']}"
      end
    end
  end
end
