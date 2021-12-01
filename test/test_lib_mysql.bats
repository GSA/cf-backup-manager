function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/common'
  _common_setup

  TEST_DATASTORE_BUCKET=datastore-backup-test
  VCAP_SERVICES="$(cat $(test_fixture mysql-test.vcap.json))"

  source $PROJECT_ROOT/lib/core.bash
  source $PROJECT_ROOT/lib/mysql.bash
}

@test "mysql:service_get_credentials_env" {
  VCAP_SERVICES="$VCAP_SERVICES" DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3 run service_get_credentials_env application-db
  assert_success
  assert_output - <<EOF
DB_HOST="mysql"
DB_PASSWORD="mysql-password"
DB_PORT="3306"
DB_USER="app"
DB_NAME="application"
EOF
}
