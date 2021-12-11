#!/bin/bash
# Run this script on FCS inventory-harvester-xyz

set -o errexit
set -o pipefail
set -o nounset

AWS_DEFAULT_REGION=us-gov-west-1
service_name=inventory-db

cat <<EOF
This script exports the $service_name datastore to s3 for re-import into the cloud.gov environment. We'll prompt you for the credentials necessary to access the backup-manager-s3 bucket. To get the credentials, use the service key.

    $ cf service-key datastore-backups fcs-migration

EOF

# prompt for secrets
read -p 'AWS_ACCESS_KEY_ID> ' AWS_ACCESS_KEY_ID
read -p 'AWS_SECRET_ACCESS_KEY> ' AWS_SECRET_ACCESS_KEY
read -p 'BUCKET_NAME> ' BUCKET_NAME
read -p 'db source environment (staging/prod)> ' space_name
export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION

# Source credentials for FCS environment
source ~/.env

backup_path_ckan="/fcs-migration/$space_name/${service_name}-ckan-$(date +%Y%m%d-%H%M%S)-migration.sql.gz"
backup_path_datastore="/fcs-migration/$space_name/${service_name}-datastore-$(date +%Y%m%d-%H%M%S)-migration.sql.gz"

time pg_dump --format=custom -h $DB_HOST_CKAN -U $DB_USER_CKAN -p $DB_PORT_CKAN datagov_Inventory_db | gzip | aws s3 cp - s3://${BUCKET_NAME}${backup_path_ckan}

time pg_dump --format=custom -h $DB_HOST_DATASTORE -U $DB_USER_DATASTORE -p $DB_PORT_DATASTORE datagov_DataPusher_db | gzip | aws s3 cp - s3://${BUCKET_NAME}${backup_path_datastore}

cat <<EOF
$service_name ($space_name) backup complete.
backup_path_ckan is: $backup_path_ckan
backup_path_ckan is: $backup_path_datastore
EOF
