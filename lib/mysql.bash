
function service_get_type () {
  :
}

# Output service credentials as env variables
function service_get_credentials_env () {
  local service_metadata="$1"
  cat <<EOF
DB_HOST="$(jq -r -e '.credentials.host' < $service_metadata)"
DB_PASSWORD="$(jq -r -e '.credentials.password' < $service_metadata)"
DB_PORT="$(jq -r -e '.credentials.port' < $service_metadata)"
DB_USER="$(jq -r -e '.credentials.username' < $service_metadata)"
DB_NAME="$(jq -r -e '.credentials.db_name' < $service_metadata)"
EOF
}

function service_backup () {
  local s3_bucket_object="$1"
  mysqldump --host="$DB_HOST" --port="$DB_PORT" --password="$DB_PASSWORD" --user "$DB_USER" --no-create-db --verbose "$DB_NAME" | gzip | AWS_ACCESS_KEY_ID="$DATASTORE_BUCKET_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$DATASTORE_BUCKET_SECRET_ACCESS_KEY" aws --endpoint "$DATASTORE_BUCKET_ENDPOINT" s3 cp - ${s3_bucket_object}.sql.gz
}

function service_restore () {
  aws --endpoint "$DATASTORE_BUCKET_ENDPOINT" s3 cp ${s3_bucket_object}.sql.gz - | gzip | mysql --host "$DB_HOST" --password="$DB_PASSWORD" --user "$DB_USER" --no-create-db --verbose "$DB_NAME"
}
