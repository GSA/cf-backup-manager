#!/bin/bash
# Run this script on FCS catalog-harvester-xyz

set -o errexit
set -o pipefail
set -o nounset

AWS_DEFAULT_REGION=us-gov-west-1
service_name=catalog-db

cat <<EOF
This script exports the $service_name datastore to s3 for re-import into the cloud.gov environment. We'll prompt you for the credentials necessary to access the backup-manager-s3 bucket. To get the credentials, use the service key.

    $ cf service-key datastore-backups fcs-migration

EOF

# prompt for secrets
read -p 'AWS_ACCESS_KEY_ID> ' AWS_ACCESS_KEY_ID
read -p 'AWS_SECRET_ACCESS_KEY> ' AWS_SECRET_ACCESS_KEY
read -p 'BUCKET_NAME> ' BUCKET_NAME
read -p 'environment (staging/prod)> ' space_name
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION

# Source credentials for FCS environment
source ~/.env

backup_path="/fcs-migration/$space_name/${service_name}-$(date +%Y%m%d-%H%M%S)-migration.sql.gz"

time pg_dump --format=custom -h $DB_HOST -U $DB_USER -p $DB_PORT -T spatial_ref_sys ckan | gzip | aws s3 cp - s3://${BUCKET_NAME}${backup_path}

cat <<EOF
$service_name ($space_name) backup complete.

Run this command to complete the migration.

  $ cf target -s $space_name

  $ PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "$DB_NAME" -c "create database ckan_temp;"
  $ PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "ckan_temp" -c "drop extension IF EXISTS postgis cascade;"
  $ PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "ckan_temp" -c "select pg_terminate_backend(pid) from pg_stat_activity where datname='$DB_NAME';"
  $ PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "ckan_temp" -c "drop database $DB_NAME;"
  $ PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "ckan_temp" -c "create database $DB_NAME;"
  $ PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "$DB_NAME" -c "create extension if not exists postgis;"
  $ PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "$DB_NAME" -c "create extension if not exists fuzzystrmatch;"
  $ PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "$DB_NAME" -c "create extension if not exists postfis_tiger_geocoder;"
  $ PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "$DB_NAME" -c "create extension if not exists postgis_topology;"
  $ PGPASSWORD=$DB_PASS psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d "$DB_NAME" -c "drop database ckan_temp;"
    
  $ time cf run-task backup-manager --wait --name "$service_name restore" --command "restore psql $service_name $backup_path"
  
  $ cf run-task catalog -c "ckan db upgrade"
  $ cf run-task catalog -c "ckan db search-index rebuild"

EOF