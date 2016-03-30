Squash::Ruby.configure api_host: Settings.SQUASH.API_HOST,
                       api_key: Settings.SQUASH.API_KEY,
                       disabled: Settings.SQUASH.DISABLED,
                       environment: Settings.SQUASH.ENVIRONMENT || Rails.env,
                       revision_file: File.join(Rails.root, "REVISION")
