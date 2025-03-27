begin
  MaisOrcidClient.configure(
    client_id: Settings.MAIS.CLIENT_ID,
    client_secret: Settings.MAIS.CLIENT_SECRET,
    base_url: Settings.MAIS.BASE_URL,
    token_url: Settings.MAIS.TOKEN_URL
  )
rescue StandardError => e
  # as of v0.3.1, mais_orcid_client tries to connect immediately upon configuration, which would
  # prevent running tests or rails console on laptop.  would also prevent deployment or startup
  # of sul_pub if configuration was incorrect (missing settings, stale password, etc).
  Rails.logger.warn("Error configuring MaisOrcidClient: #{e}")
  Honeybadger.notify(e)
end
