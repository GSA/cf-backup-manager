# psql service implements the service API

# Output service credentials as env variables
function service_get_credentials_env () {
  local service_name="${1:-}"
  [[ -z "$service_name" ]] && fail service_get_credentials_env passed an empty service_name

  cat <<EOF
DB_HOST="$(get_service_instance "$service_name" | jq -r -e '.credentials.host')"
DB_PASSWORD="$(get_service_instance "$service_name" | jq -r -e '.credentials.password')"
DB_PORT="$(get_service_instance "$service_name" | jq -r -e '.credentials.port')"
DB_USER="$(get_service_instance "$service_name" | jq -r -e '.credentials.username')"
DB_NAME="$(get_service_instance "$service_name" | jq -r -e '.credentials.db_name')"
EOF
}

# See comment for more info,
# https://github.com/GSA/datagov-deploy/issues/2788#issuecomment-983806227
function service_backup () {
  PGPASSWORD=$DB_PASSWORD pg_dump -h "$DB_HOST" -U "$DB_USER" -p "$DB_PORT" --format=custom --no-acl --no-owner --clean "$DB_NAME"
}

function service_restore () {
  PGPASSWORD=$DB_PASSWORD pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" --no-owner --clean -d "$DB_NAME"
}
