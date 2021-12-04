# Prints the service metata matching the instance_name given
# stdin: VCAP_SERVICES metadata
# params:
#   service_name: The name of the service to find
# stdout:
#   JSON metadata for the named VCAP service
function get_service_instance () {
  local service_name=$1
  jq -e ".[][] | select(.instance_name==\"${service_name}\")" <<< "$VCAP_SERVICES" || fatal "$service_name does not exist in VCAP_SERVICES"
}

# Prints S3 bucket credentials for environment
function backup_manager_bucket_credentials_env () {
  [[ -z "$BACKUP_MANAGER_S3_SERVICE_NAME" ]] && fatal "BACKUP_MANAGER_S3_SERVICE_NAME is not set"
  [[ -z "$(get_service_instance "$BACKUP_MANAGER_S3_SERVICE_NAME")" ]] && fatal "BACKUP_MANAGER_S3_SERVICE_NAME ($BACKUP_MANAGER_S3_SERVICE_NAME) does not exist in VCAP_SERVICES"

cat <<EOF
BACKUP_MANAGER_BUCKET_NAME="$(get_service_instance "$BACKUP_MANAGER_S3_SERVICE_NAME" | jq -r -e '.credentials.bucket')"
BACKUP_MANAGER_BUCKET_ACCESS_KEY_ID="$(get_service_instance "$BACKUP_MANAGER_S3_SERVICE_NAME" | jq -r -e '.credentials.access_key_id')"
BACKUP_MANAGER_BUCKET_SECRET_ACCESS_KEY="$(get_service_instance "$BACKUP_MANAGER_S3_SERVICE_NAME" | jq -r -e '.credentials.secret_access_key')"
BACKUP_MANAGER_BUCKET_REGION="$(get_service_instance "$BACKUP_MANAGER_S3_SERVICE_NAME" | jq -r -e '.credentials.region')"
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
  if [[ -n "${BACKUP_MANAGER_BUCKET_ENDPOINT:-}" ]]; then
    aws_arguments="--endpoint=$BACKUP_MANAGER_BUCKET_ENDPOINT"
  fi

  aws $aws_arguments "$@"
}

function fatal () {
  echo error: "$*" >&2
  exit 2
}
