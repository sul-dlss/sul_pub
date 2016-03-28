
[![Build Status](https://travis-ci.com/sul-dlss/sul-pub.svg?token=3yDDLeXpkveNfSKW8sHq&branch=master)](https://travis-ci.com/sul-dlss/sul-pub)

# SUL Bibliographic Management System
 
[*SUL Bibliographic Management System*](http://sulcap-dev.stanford.edu/)
by [Stanford University Libraries](http://library.stanford.edu).

## Configuration

Configurations are currently being managed in multiple ways. The goal is to [consolidate](https://github.com/sul-dlss/sul-pub/issues/99) the approach. New configurations should be added in [`settings.yml`](https://github.com/sul-dlss/sul-pub/blob/master/config/application.yml). _Never check in private settings._ This project uses the [config gem](https://github.com/railsconfig/config) for managing settings. Private settings can be added locally in a *.local.yml file. See [Developer specific config files](https://github.com/railsconfig/config#developer-specific-config-files).

Legacy configuration files to review are:
- https://github.com/sul-dlss/sul-pub/blob/master/config/application.yml
  - Application configuration parameters (may not require any changes)
- https://github.com/sul-dlss/sul-pub/blob/master/config/database.yml 
  - MySQL connection parameters
- https://github.com/sul-dlss/sul-pub/blob/master/config/cap_auth.yaml.example
  - Authentication credentials for the CAP API
  - API routes

# Developer Setup

This is a ruby on rails application with an rspec test suite.  The ruby version currently used could be any version used in the [.travis.yml](https://github.com/sul-dlss/sul-pub/blob/master/.travis.yml) configuration file (preferably the latest stable version).  The application gems are managed by bundler, so the gem versions are all defined in the Gemfile (and Gemfile.lock).

### Code Conventions

The conventions to follow are noted in the [DLSS developer playbook](https://github.com/sul-dlss/DeveloperPlaybook).  The code style conventions are checked by rubocop, using the [DLSS cops](https://github.com/sul-dlss/dlss_cops).

## Initial Setup

```sh
git clone git@github.com:sul-dlss/sul-pub.git
cd sul-pub
bundle install
```

## Database Setup

The application uses MySQL.  Install MySQL, review `config/database.yml`, and run some rake tasks to confirm everything is working, e.g.:

```sh
bundle exec rake db:create
bundle exec rake db:migrate
```

## Running the Test Suite

The test suite uses the VCR gem to manage HTTP request and response data.  The configuration for VCR does not and should not allow new HTTP requests that are not managed by VCR.  When any new specs require retrieval of data from subscription services, the private configuration files must be used (see below).  Otherwise, the existing VCR cassettes should suffice.

To run the test suite:

```sh
# If necessary, use private configuration files.
bundle exec rake ci
```

To run specific tests, use `rspec` directly, e.g.

```sh
# Run only the publications_api_spec:
RAILS_ENV=test bundle exec rspec spec/api/publications_api_spec.rb
# Run only a subset of the publications_api_spec:
RAILS_ENV=test bundle exec rspec spec/api/publications_api_spec.rb:157
```

### Private Configuration Files

There are private configuration data for this application, manged in a
[private github repository](https://github.com/sul-dlss/shared_configs). These configuration files contain private credentials for access to subscription resources and for client access to the application API.

### Updating the VCR Cassettes Using Private Configuration Files

First, follow the instructions above for using private configuration files.  Then run the test suite and commit any changes to the VCR cassettes.

```sh
# See commands above for using private configuration files.
rm -rf fixtures/vcr_cassettes/*
bundle exec rake ci
git add fixtures/vcr_cassettes/
git commit -m "Update VCR cassettes"
git reset --hard  # cleanup the private configuration files
```

## Deployment

The application is deployed using capistrano (see `cap -T` for a list of available tasks).  A developer can deploy the application when they have Kerberos authentication enabled for the remote user@host definition of the deployment target.  The `config/deploy` path in the private configuration files (see above) contains all the deployment target definitions, see:
- https://github.com/sul-dlss/shared_configs/tree/sulcap-laptop/config/deploy
