# mysql service implements the service API

# Output service credentials as env variables
function service_get_credentials_env () {
  local service_name="${1:-}"
  [[ -z "$service_name" ]] && fatal service_get_credentials_env passed an empty service_name
  [[ -z "$(get_service_instance "$service_name")" ]] && fatal "$service_name does not exist"

  cat <<EOF
DB_HOST="$(get_service_instance "$service_name" | jq -r -e '.credentials.host')"
DB_PASSWORD="$(get_service_instance "$service_name" | jq -r -e '.credentials.password')"
DB_PORT="$(get_service_instance "$service_name" | jq -r -e '.credentials.port')"
DB_USER="$(get_service_instance "$service_name" | jq -r -e '.credentials.username')"
DB_NAME="$(get_service_instance "$service_name" | jq -r -e '.credentials.db_name')"
EOF
}

function service_backup () {
  [[ -z "$DB_HOST" ]] && fatal "DB_HOST is not set correctly"
  [[ -z "$DB_NAME" ]] && fatal "DB_NAME is not set correctly"
  [[ -z "$DB_PASSWORD" ]] && fatal "DB_PASSWORD is not set correctly"
  [[ -z "$DB_PORT" ]] && fatal "DB_PORT is not set correctly"
  [[ -z "$DB_USER" ]] && fatal "DB_USER is not set correctly"

  mysqldump --no-tablespaces --host="$DB_HOST" --port="$DB_PORT" --password="$DB_PASSWORD" --user="$DB_USER" --no-create-db --verbose "$DB_NAME"
}

function service_restore () {
  [[ -z "$DB_HOST" ]] && fatal "DB_HOST is not set correctly"
  [[ -z "$DB_NAME" ]] && fatal "DB_NAME is not set correctly"
  [[ -z "$DB_PASSWORD" ]] && fatal "DB_PASSWORD is not set correctly"
  [[ -z "$DB_PORT" ]] && fatal "DB_PORT is not set correctly"
  [[ -z "$DB_USER" ]] && fatal "DB_USER is not set correctly"

  mysql --binary-mode --host="$DB_HOST" --port="$DB_PORT" --password="$DB_PASSWORD" --user="$DB_USER" "$DB_NAME"
}
