# backup database to a dump zip file in S3 bucket cg-2bd85037-4eb6-450a-87f4-460d932a6c40

set -o errexit
set -o pipefail
set -o nounset

# Get input params
# Service name: the name of the service that is hosting the S3 Backup
# Backup path: the path in S3 that is the backup location
# Storage size (in GB): minimum 250 for catalog
space_name=$(cf t | grep "space" | cut -d ':' -f 2 | awk '{$1=$1};1')

function wait_for () {
  while ! (cf tasks backup-manager | grep -q "$1 .*SUCCEEDED"); do
    sleep 5
  done
}

cf set-env backup-manager DATASTORE_S3_SERVICE_NAME backup-manager-s3

backup_id=$$
backup_path="inventory-db-$(date +%Y%m%d-%H%M%S)-$space_name.gz" 

cf run-task backup-manager  --name "inventory-db-backup-$backup_id" --command "backup psql inventory-db $backup_path"

wait_for "catalog-db-backup-$backup_id"
