# CKAN DB MIGRATION SCRIPT - Catalog-variant
# Steps to prepare catalog db for ckan migrate restore
cat << EOF
Initial Conditions/Assumptions:
  - Catalog app has a catalog-db service bound to it
  - cf delete-service catalog-db-migrate
  - cf delete-service catalog-db-venerable
  - cf set-env backup-manager DATASTORE_S3_SERVICE_NAME backup-manager-s3
EOF

set -o errexit
set -o pipefail
set -o nounset

# Get input params
# Service name: the name of the service that is hosting the S3 Backup
# Backup path: the path in S3 that is the backup location
# Storage size (in GB): minimum 350 for catalog
read -p "Space name> " space_name
read -p "S3 Backup path> " backup_path
read -p "Storage size for new db> " storage_size

function wait_for () {

  while ! (cf tasks backup-manager | grep -q "$1 .*SUCCEEDED"); do
    sleep 5
  done
}

catalog_db_migrate=catalog-db-migrate
# Go to the correct space
cf target -s $space_name

# Create Migration Database
# time cf create-service aws-rds micro-psql catalog-db-migrate --wait
time cf create-service aws-rds large-gp-psql-redundant "$catalog_db_migrate" -c "{\"storage\": ${storage_size}, \"version\": \"12\"}" --wait
cf bind-service backup-manager "$catalog_db_migrate"

# Connect to the database and get credentials in env
# Ensure the service-connect plugin is installed for cf cli,
# https://github.com/cloud-gov/cf-service-connect#local-installation
# The following extensions are created by catalog postgis install,
#   CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
#   CREATE EXTENSION IF NOT EXISTS postgis_tiger_geocoder;
#   CREATE EXTENSION IF NOT EXISTS postgis_topology;
# However, the test data loads without them.  Verified with small data restore 
# from fuhu local ckan.

# Need to bind to a running service, so if catalog is stopped use backup-manager
cf connect-to-service backup-manager "$catalog_db_migrate" << EOF
CREATE EXTENSION IF NOT EXISTS postgis;
EOF

# Restore backup
restore_id=$$
time cf run-task backup-manager --name "catalog-restore-$restore_id" --command "PG_RESTORE_OPTIONS='--no-acl' restore psql $catalog_db_migrate $backup_path"

# This job may return "FAILED", and may not return successfully
wait_for "catalog-restore-$restore_id"

cf connect-to-service backup-manager "$catalog_db_migrate" << EOF
drop index idx_package_resource_package_id;
drop index idx_package_resource_revision_period;
EOF

# Bind to new database
cf rename-service catalog-db catalog-db-venerable
cf rename-service "$catalog_db_migrate" catalog-db
cf unbind-service catalog catalog-db-venerable
cf bind-service catalog catalog-db

# # Upgrade DB and reindex SOLR
cf scale catalog -i 0
cf run-task catalog -c "ckan db upgrade"
cf scale catalog -i 2
cf run-task catalog -c "ckan search-index rebuild -i -o -e" --name search-index-rebuild -k 2G -m 2G
