#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset

. lib/core.bash

function usage () {
  cat <<EOF >&2
$0: <command> <service_type> <service> <path> [options]
Backup and restore utility

  command: backup or restore
  service_type: the type of service to backup/restore (e.g. mysql or postgresql)
  service: the service name to backup/restore
  path: the path to store/retrieve backups within the bucket

Environment variables:

  DATASTORE_S3_SERVICE_NAME: the name of the S3 service to store backups.

EOF
}

function fail () {
  echo "$*" >&2
  exit 2
}

function main () {
  local service_metadata service_name service_type

  service_type="$1"
  shift
  service_name="$1"
  shift
  datastore_bucket_path="$1"
  shift


  # Get credentials for the datastore S3 bucket
  local datastore_s3_credentials=$DATA_DIR/datastore_s3_credentials
  local datastore_s3_metadata=$DATA_DIR/datastore_s3_metadata
  get_service_instance "$DATASTORE_S3_SERVICE_NAME" <<< "$VCAP_SERVICES" > "$datastore_s3_metadata"
  [ -s "$datastore_s3_metadata" ] || fail "Error: DATASTORE_S3_SERVICE_NAME=$DATASTORE_S3_SERVICE_NAME could not be found in VCAP_SERVICES."
  get_datastore_bucket_credentials_env "$datastore_s3_metadata" > "$datastore_s3_credentials"
  source "$datastore_s3_credentials"

  # Get metadata for the target service
  service_metadata=$DATA_DIR/service_metadata
  get_service_instance "$service_name" <<< "$VCAP_SERVICES" > "$service_metadata"
  [ -s "$service_metadata" ] || fail "Error: service=$service_name could not be found in VCAP_SERVICES."

  time (
    set -o errexit
    set -o pipefail

    # Load the service
    source $PROJECT_DIR/lib/${service_type}.bash

    # Get credentials for the target service
    service_credentials=$DATA_DIR/credentials
    service_get_credentials_env "$service_metadata" > "$service_credentials"

    source "$datastore_s3_credentials"
    cat "$datastore_s3_credentials"
    source "$service_credentials"
    cat "$service_credentials"
    service_${command} "s3://${DATASTORE_BUCKET_NAME}/${datastore_bucket_path}/${service_name}-$(date +%Y%m%d%H%M%S)-backup"
  )
}

DATASTORE_S3_SERVICE_NAME=${DATASTORE_S3_SERVICE_NAME:-""}
if [ -z "$DATASTORE_S3_SERVICE_NAME" ]; then
  echo "DATASTORE_S3_SERVICE_NAME not set. This should be the name of the S3 service to store backups." >&2
  usage
  exit 1
fi

DATA_DIR="$(mktemp -d)"

function cleanup () {
  rm -rf "$DATA_DIR"
}

trap cleanup EXIT


command="$1"
shift




case $command in
  backup|restore)
    if [[ "$#" -lt 3 ]]; then
      usage
      exit 1
    fi
    main "$@"
    ;;

  help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown command: $command" >&2
    usage
    exit 1
    ;;
esac
