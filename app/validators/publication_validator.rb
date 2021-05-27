# frozen_string_literal: true

class PublicationValidator < ActiveModel::Validator
  def validate(record)
    errors = PubHashValidator.validate(record.pub_hash)
    Honeybadger.notify('[PUB_HASH VALIDATION ERROR]', context: { publication_id: record.id, message: errors }) if errors.present?

    # to fail when validating, add the errors to the object
    # errors.each { |error| record.errors.add :pub_hash, error }
  end
end
