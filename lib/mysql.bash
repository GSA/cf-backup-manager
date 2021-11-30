
function service_get_type () {
  :
}

# Output service credentials as env variables
function service_get_credentials_env () {
  local service_name="$1"
  [[ -z "$service_name" ]] && fail service_get_credentials_env passed an empty service_name

  cat <<EOF
DB_HOST="$(get_service_instance "$service_name" | jq -r -e '.credentials.host')"
DB_PASSWORD="$(get_service_instance "$service_name" | jq -r -e '.credentials.password')"
DB_PORT="$(get_service_instance "$service_name" | jq -r -e '.credentials.port')"
DB_USER="$(get_service_instance "$service_name" | jq -r -e '.credentials.username')"
DB_NAME="$(get_service_instance "$service_name" | jq -r -e '.credentials.db_name')"
EOF
}

function service_backup () {
  local s3_bucket_object="$1"
  mysqldump --host="$DB_HOST" --port="$DB_PORT" --password="$DB_PASSWORD" --user "$DB_USER" --no-create-db --verbose "$DB_NAME" | gzip | AWS_ACCESS_KEY_ID="$DATASTORE_BUCKET_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$DATASTORE_BUCKET_SECRET_ACCESS_KEY" aws --endpoint "$DATASTORE_BUCKET_ENDPOINT" s3 cp - ${s3_bucket_object}.sql.gz
}

function service_restore () {
  aws --endpoint "$DATASTORE_BUCKET_ENDPOINT" s3 cp ${s3_bucket_object}.sql.gz - | gzip | mysql --host "$DB_HOST" --password="$DB_PASSWORD" --user "$DB_USER" --no-create-db --verbose "$DB_NAME"
}
