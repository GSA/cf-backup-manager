#!/bin/bash

# CKAN DB MIGRATION SCRIPT - Inventory-variant
# Steps to prepare inventory db for ckan migrate restore
cat << EOF
Initial Conditions/Assumptions:
  - Works on CF version 7 for wait on cf run-task
  - Inventory app has inventory-db services bound to it
  - cf delete-service inventory-db-migrate
  - cf delete-service inventory-db-venerable
EOF

set -o errexit
set -o pipefail
set -o nounset

function wait_for () {

  while ! cf service $1 | grep 'status:.*succeeded'; do
    sleep 10
  done
}

# Get input params
# Service name: the name of the service that is hosting the S3 Backup
# Backup path: the path in S3 that is the backup location
read -p "Space name to retore to> " space_name
read -p "name of service restore to (inventory-db)> " service_name
read -p "storage size>" storage_size
read -p "S3 Backup path> " backup_path

# Go to the correct space
cf target -s $space_name

# Create Migration Database
cf create-service aws-rds medium-psql-redundant ${service_name}-migrate -c "{\"storage\": $storage_size}"
wait_for ${service_name}-migrate
cf bind-service backup-manager ${service_name}-migrate

# Connect to the database and get credentials in env
# Ensure the service-connect plugin is installed for cf cli,
# https://github.com/cloud-gov/cf-service-connect#local-installation

# Restore backup
####################################
# this will exit with code 1 due to the following error
# pg_restore: error: could not execute query: ERROR: schema "public" already exists
####################################
cf run-task backup-manager --name "inventory-restore" --command "PG_RESTORE_OPTIONS='--no-acl' restore psql ${service_name}-migrate $backup_path" --wait

# user table fix
cf connect-to-service inventory ${service_name}-migrate << EOF
UPDATE "user" SET fullname = email WHERE fullname IS NULL or fullname = '';
UPDATE "user" SET name = REGEXP_REPLACE(name, '[^a-zA-Z0-9-]', '_', 'g');
EOF

# Bind to new database
cf rename-service ${service_name} ${service_name}-venerable
cf rename-service ${service_name}-migrate ${service_name}
cf unbind-service inventory ${service_name}-venerable
cf bind-service inventory ${service_name}

# Upgrade DB and reindex SOLR
cf stop inventory
cf run-task inventory -c "ckan db upgrade" --wait
cf restart inventory
cf run-task inventory -c "ckan search-index rebuild" --wait
