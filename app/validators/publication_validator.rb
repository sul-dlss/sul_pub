# frozen_string_literal: true

class PublicationValidator < ActiveModel::Validator
  def validate(record)
    PubHashValidator.validate(record.pub_hash).each { |error| record.errors.add :pub_hash, error }
  end
end
