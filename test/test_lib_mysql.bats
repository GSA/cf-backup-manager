# Unit test mysql functions in lib/mysql.bash

function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/common'
  load 'test_helper/mysql'
  _common_setup

  TEST_DATASTORE_BUCKET=datastore-backup-test
  VCAP_SERVICES="$(cat $(test_fixture mysql-test.vcap.json))"
  DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3

  source $PROJECT_ROOT/lib/core.bash
  source $PROJECT_ROOT/lib/mysql.bash

  wait_for mysql_cmd <<SQL
select 1;
SQL
}

@test "mysql:service_get_credentials_env" {
  run service_get_credentials_env application-mysql-db
  assert_success
  assert_output - <<EOF
DB_HOST="mysql"
DB_PASSWORD="mysql-password"
DB_PORT="3306"
DB_USER="app"
DB_NAME="application-mysql-db"
EOF
}

@test "mysql:service_backup" {
  # These credentials should match the docker-compose environment
  DB_NAME=application-mysql-db
  DB_USER=app
  DB_PORT=3306
  DB_HOST=mysql
  DB_PASSWORD=mysql-password

  run service_backup
  assert_success
  assert_output --regexp  '-- MariaDB dump\s+[0-9]+\.[0-9]+\s+Distrib [0-9]+\.[0-9]+\.[0-9]+-MariaDB, for Linux \(x86_64\)'
  assert_output --partial '-- Host: mysql    Database: application-mysql-db'
  assert_output --regexp  '-- Server version\s+[0-9]+\.[0-9]+\.[0-9]+'
}
