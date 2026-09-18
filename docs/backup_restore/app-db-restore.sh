# restore catalog-db from a dump zip file in S3 bucket cg-2bd85037-4eb6-450a-87f4-460d932a6c40

set -o errexit
set -o pipefail
set -o nounset

# Service name: the name of the service that is hosting the S3 Backup
# Backup path: the path in S3 that is the backup location
read -rp "S3 Backup path> " backup_path
read -rp "New Service name> " service_name

function wait_for () {
  while ! (cf tasks backup-manager | grep -q "$1 .*SUCCEEDED"); do
    sleep 5
  done
}

cf set-env backup-manager DATASTORE_S3_SERVICE_NAME backup-manager-s3
cf bind-service backup-manager "$service_name"
cf restart backup-manager

# # Restore backup
restore_id=$$
cf run-task backup-manager --name "db-restore-$restore_id" --command "PG_RESTORE_OPTIONS='--no-acl' restore psql $service_name $backup_path"

# # This job may return "FAILED", and may not return successfully
wait_for "db-restore-$restore_id"

