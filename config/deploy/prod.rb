# see https://github.com/sul-dlss/sul_pub/wiki/Servers-Deployment-environment
server 'sul-pub-prod.stanford.edu', user: 'pub', roles: %w(web db app harvester_prod external_monitor)
