# Prints the service metata matching the instance_name given
# stdin: VCAP_SERVICES metadata
# params:
#   service_name: The name of the service to find
# stdout:
#   JSON metadata for the named VCAP service
function get_service_instance () {
  local service_name=$1
  jq -e ".[][] | select(.instance_name==\"${service_name}\")" <<< "$VCAP_SERVICES"
}

# Prints the service type
function get_service_type () {
  :
}

# Prints S3 bucket credentials for environment
function get_datastore_bucket_credentials_env () {
  [[ -z "$DATASTORE_S3_SERVICE_NAME" ]] && fail "DATASTORE_S3_SERVICE_NAME is not set to a serivice in VCAP_SERVICES"

  cat <<EOF
DATASTORE_BUCKET_NAME="$(get_service_instance "$DATASTORE_S3_SERVICE_NAME" | jq -r -e '.credentials.bucket')"
DATASTORE_BUCKET_ACCESS_KEY_ID="$(get_service_instance "$DATASTORE_S3_SERVICE_NAME" | jq -r -e '.credentials.access_key_id')"
DATASTORE_BUCKET_SECRET_ACCESS_KEY="$(get_service_instance "$DATASTORE_S3_SERVICE_NAME" | jq -r -e '.credentials.secret_access_key')"
DATASTORE_BUCKET_REGION="$(get_service_instance "$DATASTORE_S3_SERVICE_NAME" | jq -r -e '.credentials.region')"
EOF
}

# Echo the name of a tempfile based on BACKUP_MANAGER_TMPDIR directory
function env_file () {
  local backup_manager_tmpdir=${BACKUP_MANAGER_TMPDIR:-${TMPDIR:-/tmp}}
  echo $backup_manager_tmpdir/$1
}

# Wrapper around the AWS CLI to provide an alternative endpoint for testing environments
function aws_cmd () {
  local aws_arguments=""
  if [[ -n "${DATASTORE_BUCKET_ENDPOINT:-}" ]]; then
    aws_arguments="--endpoint=$DATASTORE_BUCKET_ENDPOINT"
  fi

  aws $aws_arguments "$@"
}

function fatal () {
  echo "$*" >&2
  return 2
}
