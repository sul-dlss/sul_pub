class Settings < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
  load!

  def sw_doc_types_to_skip
    @doc_types_to_skip ||= sw_doc_types_to_skip_a.join('|')
  end
end
