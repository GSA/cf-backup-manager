# Prints the service metata matching the instance_name given
# stdin: VCAP_SERVICES metadata
# params:
#   service_name: The name of the service to find
# stdout:
#   JSON metadata for the named VCAP service
function get_service_instance () {
  local service_name=$1
  jq -e ".[][] | select(.instance_name==\"${service_name}\")"
}

# Prints the label and plan, separated by space
# stdin: Single VCAP service instance metadata
# stdout:
#   Output service label and plan e.g. "aws-rds small-psql"
function get_service_label_plan () {
  jq --raw-output '[.label, .plan] | join(" ")'
}

# Prints the service type
function get_service_type () {
  :
}

# Prints S3 bucket credentials for environment
function get_datastore_bucket_credentials_env () {
  local service_metadata="$1"
  cat <<EOF
DATASTORE_BUCKET_NAME="$(jq -r -e '.credentials.bucket' < $service_metadata)"
DATASTORE_BUCKET_ACCESS_KEY_ID="$(jq -r -e '.credentials.access_key_id' < $service_metadata)"
DATASTORE_BUCKET_SECRET_ACCESS_KEY="$(jq -r -e '.credentials.secret_access_key' < $service_metadata)"
DATASTORE_BUCKET_REGION="$(jq -r -e '.credentials.region' < $service_metadata)"
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
