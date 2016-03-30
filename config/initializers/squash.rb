Squash::Ruby.configure api_host: ConfigSettings.SQUASH.API_HOST,
                       api_key: ConfigSettings.SQUASH.API_KEY,
                       disabled: ConfigSettings.SQUASH.DISABLED,
                       environment: ConfigSettings.SQUASH.ENVIRONMENT || Rails.env,
                       revision_file: File.join(Rails.root, "REVISION")
