# Unit test mysql functions in lib/mysql.bash

function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/common'
  load 'test_helper/mysql'
  _common_setup

  VCAP_SERVICES="$(cat $(test_fixture mysql-test.vcap.json))"
  BACKUP_MANAGER_S3_SERVICE_NAME=datastore-backup-test-s3

  source $PROJECT_ROOT/lib/core.bash
  source $PROJECT_ROOT/lib/mysql.bash

  wait_for mysql_cmd <<SQL > /dev/null
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

@test "mysql:service_get_credentials_env given no service, fails" {
  run service_get_credentials_env
  assert_failure
  assert_output "error: service_get_credentials_env passed an empty service_name"
}

@test "mysql:service_get_credentials_env given non-existant service, fails" {
  run service_get_credentials_env nonexist-db
  assert_failure
  assert_output --partial "error: nonexist-db does not exist"
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

@test "mysql:service_backup given missing variables, fails" {
  # These credentials should match the docker-compose environment
  DB_NAME=application-mysql-db
  DB_USER=
  DB_PORT=
  DB_HOST=
  DB_PASSWORD=

  run service_backup
  assert_failure
  assert_output --partial "error: DB_HOST is not set correctly"
}
