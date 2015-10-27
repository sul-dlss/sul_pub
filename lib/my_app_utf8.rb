module MyAppUtf8
  class SetNamesUtf8
    def self.filter(_controller)
      suppress(ActiveRecord::StatementInvalid) do
        ActiveRecord::Base.connection.execute 'SET NAMES UTF8'
      end
      true
    end
  end
end
