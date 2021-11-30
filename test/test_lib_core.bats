#!/usr/bin/env bats

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # get the containing directory of this file use $BATS_TEST_FILENAME instead
    # of ${BASH_SOURCE[0]} or $0, as those will point to the bats executable's
    # location or the preprocessed file respectively
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$PROJECT_ROOT:$PATH"
    source $PROJECT_ROOT/lib/core.bash
}

function test_fixture () {
  echo $BATS_TEST_DIRNAME/data/$1
}


@test "get_service_instance application-db is found" {
  run get_service_instance application-db < $(test_fixture example.vcap.json)

  assert_success
  assert_output - <<EOF
{
  "binding_guid": "eda9d934-a935-492a-abf5-7a2bbd126d9b",
  "binding_name": null,
  "credentials": {
    "db_name": "application",
    "host": "postgres",
    "name": "application",
    "password": "postgres-password",
    "port": "5432",
    "uri": "postgres://postgres:postgres-password@postgres:5432/application",
    "username": "app"
  },
  "instance_guid": "84ec223d-b3ba-4fd0-9648-08aebc8c9863",
  "instance_name": "application-db",
  "label": "aws-rds",
  "name": "application-db",
  "plan": "small-psql",
  "provider": null,
  "syslog_drain_url": null,
  "tags": [
    "database",
    "RDS"
  ],
  "volume_mounts": []
}
EOF
}

@test "get_service_instance nonexist-db is not found" {
  run get_service_instance nonexist-db < $(test_fixture example.vcap.json)
  assert_failure
  assert_output ""
}

@test "get_service_label_plan given mysql service instance, returns aws-rds small-mysql" {
  run get_service_label_plan < $(test_fixture mysql-service-instance.vcap.json)
  assert_success
  assert_output "aws-rds small-mysql"
}

@test "get_datastore_bucket_credentials_env" {
  run get_datastore_bucket_credentials_env $(test_fixture datastore-s3.vcap.json)

  assert_success
  assert_output - <<EOF
DATASTORE_BUCKET_NAME="datastore-backup"
DATASTORE_BUCKET_ACCESS_KEY_ID="minio"
DATASTORE_BUCKET_SECRET_ACCESS_KEY="miniopassword"
DATASTORE_BUCKET_REGION="us-gov-west-1"
EOF
}
