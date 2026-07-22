# s3 service implements the service API

function service_get_credentials_env () {
  local service_name="${1:-}"
  [[ -z "$service_name" ]] && fatal service_get_credentials_env passed an empty service_name
  [[ -z "$(get_service_instance "$service_name")" ]] && fatal $service_name does not exist in vcap_services

  cat <<EOF
S3_BUCKET_NAME="$(get_service_instance "$service_name" | jq -r -e '.credentials.bucket')"
S3_BUCKET_ACCESS_KEY_ID="$(get_service_instance "$service_name" | jq -r -e '.credentials.access_key_id')"
S3_BUCKET_SECRET_ACCESS_KEY="$(get_service_instance "$service_name" | jq -r -e '.credentials.secret_access_key')"
S3_BUCKET_REGION="$(get_service_instance "$service_name" | jq -r -e '.credentials.region')"
EOF
}

function _s3_normalize_prefix () {
  local prefix="${1:-}"
  prefix="${prefix#/}"
  prefix="${prefix%/}"
  echo "$prefix"
}

function _s3_list_keys () {
  AWS_ACCESS_KEY_ID="$S3_BUCKET_ACCESS_KEY_ID" \
    AWS_SECRET_ACCESS_KEY="$S3_BUCKET_SECRET_ACCESS_KEY" \
    AWS_DEFAULT_REGION="$S3_BUCKET_REGION" \
    aws_cmd s3api list-objects-v2 \
      --bucket "$S3_BUCKET_NAME" |
    jq -r '.Contents[]?.Key'
}

function service_backup_to_datastore () {
  local backup_path key backup_prefix
  backup_path="$(_s3_normalize_prefix "$1")"
  backup_prefix="$backup_path"

  while IFS= read -r key; do
    [[ -z "$key" ]] && continue

    AWS_ACCESS_KEY_ID="$S3_BUCKET_ACCESS_KEY_ID" \
      AWS_SECRET_ACCESS_KEY="$S3_BUCKET_SECRET_ACCESS_KEY" \
      AWS_DEFAULT_REGION="$S3_BUCKET_REGION" \
      aws_cmd s3 cp "s3://${S3_BUCKET_NAME}/${key}" - |
      AWS_ACCESS_KEY_ID="$DATASTORE_BUCKET_ACCESS_KEY_ID" \
        AWS_SECRET_ACCESS_KEY="$DATASTORE_BUCKET_SECRET_ACCESS_KEY" \
        AWS_DEFAULT_REGION="$DATASTORE_BUCKET_REGION" \
        aws_cmd s3 cp - "s3://${DATASTORE_BUCKET_NAME}/${backup_prefix}/${key}"
  done < <(_s3_list_keys)
}

function service_restore_from_datastore () {
  local backup_path key target_key
  backup_path="$(_s3_normalize_prefix "$1")"

  AWS_ACCESS_KEY_ID="$DATASTORE_BUCKET_ACCESS_KEY_ID" \
      AWS_SECRET_ACCESS_KEY="$DATASTORE_BUCKET_SECRET_ACCESS_KEY" \
      AWS_DEFAULT_REGION="$DATASTORE_BUCKET_REGION" \
      aws_cmd s3api list-objects-v2 \
      --bucket "$DATASTORE_BUCKET_NAME" \
      --prefix "${backup_path}/" |
    jq -r '.Contents[]?.Key' |
    while IFS= read -r key; do
      [[ -z "$key" ]] && continue
      target_key="${key#${backup_path}/}"

      AWS_ACCESS_KEY_ID="$DATASTORE_BUCKET_ACCESS_KEY_ID" \
        AWS_SECRET_ACCESS_KEY="$DATASTORE_BUCKET_SECRET_ACCESS_KEY" \
        AWS_DEFAULT_REGION="$DATASTORE_BUCKET_REGION" \
        aws_cmd s3 cp "s3://${DATASTORE_BUCKET_NAME}/${key}" - |
        AWS_ACCESS_KEY_ID="$S3_BUCKET_ACCESS_KEY_ID" \
          AWS_SECRET_ACCESS_KEY="$S3_BUCKET_SECRET_ACCESS_KEY" \
          AWS_DEFAULT_REGION="$S3_BUCKET_REGION" \
          aws_cmd s3 cp - "s3://${S3_BUCKET_NAME}/${target_key}"
    done
}
