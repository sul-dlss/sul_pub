[![Build Status](https://circleci.com/gh/sul-dlss/sul_pub.svg?style=svg)](https://circleci.com/gh/sul-dlss/sul_pub)
[![codecov](https://codecov.io/github/sul-dlss/sul_pub/graph/badge.svg?token=sP9x1PF9jR)](https://codecov.io/github/sul-dlss/sul_pub)

# SUL Bibliographic Management System

[*SUL Bibliographic Management System*](https://sulcap.stanford.edu/)
by [Stanford University Libraries](https://library.stanford.edu).

## Configuration

Configurations are currently being managed in multiple ways. The goal is to [consolidate](https://github.com/sul-dlss/sul-pub/issues/99) the approach. New configurations should be added in [`settings.yml`](https://github.com/sul-dlss/sul_pub/blob/main/config/application.yml). _Never check in private settings._ This project uses the [config gem](https://github.com/railsconfig/config) for managing settings. Private settings can be added locally in a *.local.yml file. See [Developer specific config files](https://github.com/railsconfig/config#developer-specific-config-files).

Legacy configuration files to review are:
- https://github.com/sul-dlss/sul_pub/blob/main/config/application.yml
  - Application configuration parameters (may not require any changes)
- https://github.com/sul-dlss/sul_pub/blob/main/config/database.yml
  - PostgreSQL connection parameters

# Developer Setup

This is a ruby on rails application with an rspec test suite.

### Code Conventions

The conventions to follow are noted in the [DLSS developer playbook](https://github.com/sul-dlss/DeveloperPlaybook).  The code style conventions are checked by rubocop.

## Initial Setup

```sh
git clone git@github.com:sul-dlss/sul_pub.git
cd sul_pub
bundle install
```

## Database Setup

The application uses PostgreSQL in all environments. As a convenience, you may spin up a local Postgres instance using `docker compose up -d postgres`, and then:

```sh
bin/rake db:prepare
```

## Running the Test Suite

The test suite uses the VCR gem to manage HTTP request and response data.  The configuration for VCR does not and should not allow new HTTP requests that are not managed by VCR.  When any new specs require retrieval of data from subscription services, the private configuration files must be used (see below).  Otherwise, the existing VCR cassettes should suffice.

To run the test suite:

```sh
# If necessary, use private configuration files.
bin/rake ci
```

To run specific tests, use `rspec` directly, e.g.

```sh
# Run only the publications_api_spec:
bundle exec rspec spec/api/publications_api_spec.rb
# Run only a subset of the publications_api_spec:
bundle exec rspec spec/api/publications_api_spec.rb:157
```

### Running integration tests

This repository also uses the RSpec tag `data-integration` to define tests that are reliant on external APIs. When creating `data-integration` specs, make sure to add the RSpec tag `'data-integration': true`.

To run the `data-integration` tests, make sure that your private credentials are appropriately configured. There is a convenient rake task to use for running the specs:

```sh
bin/rake spec:data-integration
```

### Private Configuration Files (and VCR Cassette generation)

There are private configuration data for this application, managed in a
[private github repository](https://github.com/sul-dlss/shared_configs/branches/all?query=sul-pub).
It can be useful to access the external APIs from your laptop for testing or to
create new VCR cassettes in testing.  You can use the `sul-pub-cap-dev-a` branch
for this purpose since it has the private API keys.  To do this, grab the
`config/settings/production.yml` file and save it as a `config/settings.local.yml`
file for local development.  These files are both gitignored so you don't commit by mistake,
and you can override other settings as needed.  If you are going to (re-)generate VCR cassettes
during tests, you will also need the private API keys in the test environment.  You can
use the same config file to run in your local test environment as shown below.
This is also gitignored so you won't check it in.

```sh
mkdir config/settings
cp config/settings.local.yml config/settings/test.local.yml
```

⚠️ Note: Since the VCR cassettes include the full request and response in plain text, it is important not to include any
private information in these requests, such as API keys or non-public personal information.  In order to ensure
this information is not checked in, there is configuration in `spec/spec_helper.rb` to look for private information and scrub it
from cassettes automatically as they are generated.  Look under the `VCR.configure` heading in that file for the correct format
if you need to add new filters for data that should not be checked into Github (e.g. private identifiers and API keys).

#### Updating the VCR Cassettes Using Private Configuration Files

First, follow the instructions above for obtaining the private configuration files.
Be sure you have the `config/settings/test.local.yml`.
Then remove the relevant VCR cassettes if needed, run the test suite and commit any changes to the VCR cassettes.

⚠️ Note: Same warning about filtering private info from cassettes as when recording them anew, see above.

```sh
# See commands above for using private configuration files.
rm -rf fixtures/vcr_cassettes/*
bin/rake ci
git add fixtures/vcr_cassettes/
git commit -m "Update VCR cassettes"
git reset --hard  # cleanup the private configuration files
```

## Deployment and Integration Testing

The application is deployed using capistrano (see `cap -T` for a list of available tasks).  A developer can deploy the application when they have Kerberos authentication enabled for the remote user@host definition of the deployment target. The defined deployment environments and their intended uses are here: https://github.com/sul-dlss/sul_pub/wiki/Servers-Deployment-environment

The wiki page above also describes which environments can be useful for testing against live data.

```sh
bundle exec cap [ENVIRONMENT] deploy
```

### To update shared configs on the server, use:

Note: this is automatically run on each deploy.

```sh
bundle exec cap [ENVIRONMENT] shared_configs:update
```

## Additional information

Additional information about this project is contained in the [wiki](https://github.com/sul-dlss/sul_pub/wiki).

### Publication metadata isssues

See https://github.com/sul-dlss/sul_pub/wiki/Publication-metadata-issues.

## Cron check-ins

Some cron jobs (configured via the whenever gem) are integrated with Honeybadger check-ins. These cron jobs will check-in with HB (via a curl request to an HB endpoint) whenever run. If a cron job does not check-in as expected, HB will alert.

Cron check-ins are configured in the following locations:
1. `config/schedule.rb`: This specifies which cron jobs check-in and what setting keys to use for the checkin key. See this file for more details.
2. `config/settings.yml`: Stubs out a check-in key for each cron job. Since we may not want to have a check-in for all environments, this stub key will be used and produce a null check-in.
3. `config/settings/production.yml` in shared_configs: This contains the actual check-in keys.
4. HB notification page: Check-ins are configured per project in HB. To configure a check-in, the cron schedule will be needed, which can be found with `bundle exec whenever`. After a check-in is created, the check-in key will be available. (If the URL is `https://api.honeybadger.io/v1/check_in/rkIdpB` then the check-in key will be `rkIdpB`).
