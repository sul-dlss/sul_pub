
# Constants for all example requests
CONTENT_TYPE='Content-Type: application/json'

# https://sulcap-dev.stanford.edu/rails/db/
DEV_HOST='https://sulcap-dev.stanford.edu'
DEV_API_KEY='CAPKEY: ***REMOVED***'

# Check the admin interface for contributions at
# https://sulcap-dev.stanford.edu/rails/db/tables/contributions/data
dev_data='{"cap_profile_id":"4264","sul_pub_id":"1","featured":true,"status":"approved","visibility":"private"}'
curl -X POST -H "$CONTENT_TYPE" -H "$DEV_API_KEY" -d "$dev_data" $DEV_HOST/authorship




# prod_data='{"cap_profile_id":"33208","sw_id":"73659795","featured":false,"status":"approved","visibility":"PUBLIC"}'
