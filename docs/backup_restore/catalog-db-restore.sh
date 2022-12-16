# restore catalog-db from a dump zip file in S3 bucket cg-2bd85037-4eb6-450a-87f4-460d932a6c40

set -o errexit
set -o pipefail
set -o nounset

# Get input params
# Service name: the name of the service that is hosting the S3 Backup
# Backup path: the path in S3 that is the backup location
# Storage size (in GB): minimum 250 for catalog
read -p "Space name> " space_name
read -p "S3 Backup path> " backup_path
read -p "Storage size for new db> " storage_size

function wait_for () {
  while ! (cf tasks backup-manager | grep -q "$1 .*SUCCEEDED"); do
    sleep 5
  done
}

cf set-env backup-manager DATASTORE_S3_SERVICE_NAME backup-manager-s3

# Go to the correct space
cf target -s $space_name

# # create temp Database
if [[ "${space_name}" == 'prod' ]]; then
  db_plan=large-gp-psql-redundant
else
  db_plan=large-gp-psql
fi
cf create-service aws-rds ${db_plan} catalog-db-new -c "{\"storage\": ${storage_size}, \"version\": \"12\"}" --wait
cf bind-service backup-manager catalog-db-new
cf restart backup-manager

# # Restore backup
restore_id=$$
cf run-task backup-manager --name "catalog-db-restore-$restore_id" --command "PG_RESTORE_OPTIONS='--no-acl' restore psql catalog-db-new $backup_path"

# # This job may return "FAILED", and may not return successfully
wait_for "catalog-db-restore-$restore_id"

# modify email, apikey, frequency etc only in non-prod 
if [[ "${space_name}" != 'prod' ]]; then
cf connect-to-service backup-manager catalog-db-new << EOF
update harvest_source set frequency='MANUAL';
update package_extra set value='MANUAL' where key='frequency';
update "user" set apikey=null;
delete from api_token;
update "user" set email=CONCAT(MD5(email), '@localdomain.local') where email not like '%@gsa.gov';
update public.group_extra set value = CONCAT(MD5(value), '@localdomain.local') where key='email_list' and value not like '%@gsa.gov%';
EOF
fi

# # rename database
# cf rename-service catalog-db catalog-db-venerable
# cf rename-service catalog-db-new catalog-db

# # clear solr indexes
# clear_id=$$
# cf run-task catalog-admin --name "clear-solr-index-$clear_id" -c "ckan search-index clear" 

# wait_for "clear-solr-index-$clear_id"

# # bind to new database
# cf unbind-service catalog-admin catalog-db-venerable
# cf bind-service catalog-admin catalog-db
# cf restart catalog-admin

# # # analyze DB
# cf connect-to-service backup-manager catalog-db << EOF
# ANALYZE;
# EOF

# # bind other services
# cf unbind-service catalog-web catalog-db-venerable
# cf bind-service catalog-web catalog-db
# cf restart catalog-web

# cf unbind-service catalog-gather catalog-db-venerable
# cf bind-service catalog-gather catalog-db
# cf restart catalog-gather

# cf unbind-service catalog-fetch catalog-db-venerable
# cf bind-service catalog-fetch catalog-db
# cf restart catalog-fetch

# # reindex solr
# cf run-task catalog-admin -c "ckan search-index rebuild -i -o" --name search-index-rebuild -k 2G -m 2G

# # cleanup
# cf delete-service catalog-db-venerable