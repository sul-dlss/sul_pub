module WebOfScience
  class AuthorRecordJob < ActiveJob::Base
    queue_as :wos_author_record

    # Performs an asynchronous process to save an Author contribution for a WebOfScience::Record
    # @param [Author] author
    # @param [WebOfScienceSourceRecord] wos_src_record
    def perform(author, wos_src_record)
      return unless Settings.WOS.enabled
      WebOfScience::ProcessRecord.new(author, wos_src_record).execute
    rescue => e
      msg = "WebOfScience::AuthorRecordJob.perform(#{author}, #{wos_src_record.uid})"
      NotificationManager.log_exception(logger, msg, e)
      Honeybadger.notify(e, context: { message: msg })
      raise
    end
  end
end
