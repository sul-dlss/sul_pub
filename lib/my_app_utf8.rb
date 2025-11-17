# frozen_string_literal: true

module MyAppUtf8
  class SetNamesUtf8
    def self.filter(_controller) # rubocop:disable Naming/PredicateMethod
      suppress(ActiveRecord::StatementInvalid) do
        ActiveRecord::Base.connection.execute 'SET NAMES UTF8'
      end
      true
    end
  end
end
