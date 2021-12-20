# psql integration tests

function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  load 'test_helper/common'
  load 'test_helper/psql'
  _common_setup

  # Backup DB Credentials
  TEST_DB_PASS=psql
  TEST_DB_HOST=postgres
  TEST_DB_USER=app
  TEST_DB_NAME=application_db
  # Backup DB Credentials
  TEST_DB_RESTORE_PASS=psql
  TEST_DB_RESTORE_HOST=postgres-restore
  TEST_DB_RESTORE_USER=app_restore
  TEST_DB_RESTORE_NAME=application_restore_db

  TEST_DATASTORE_BUCKET=datastore-backup-test
  export DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3

  VCAP_SERVICES="$(cat $(test_fixture psql-test.vcap.json))"
  VCAP_APPLICATION="$(cat $(test_fixture vcap-application.json))"

  # Create the bucket
  aws_helper s3api create-bucket --bucket $TEST_DATASTORE_BUCKET

  # Wait for databases to be ready
  wait_for psql_cmd -c 'select 1;'
  TEST_DB_PASS=$TEST_DB_RESTORE_PASS TEST_DB_HOST=$TEST_DB_RESTORE_HOST TEST_DB_USER=$TEST_DB_RESTORE_USER TEST_DB_NAME=$TEST_DB_RESTORE_NAME wait_for psql_cmd -c 'select 1;'

  # Initialize database with data
  psql_initdb
}

function teardown () {
  psql_cleandb
  TEST_DB_PASS=$TEST_DB_RESTORE_PASS TEST_DB_HOST=$TEST_DB_RESTORE_HOST TEST_DB_USER=$TEST_DB_RESTORE_USER TEST_DB_NAME=$TEST_DB_RESTORE_NAME psql_cleandb
  # Delete the test bucket
  aws_helper s3 rb s3://$TEST_DATASTORE_BUCKET --force
}

@test "psql init, backup, restore and verify" {
  run backup psql postgres-backup-test /psql-backup.sql.gz
  assert_success
  assert_output --partial 'backing up postgres-backup-test (psql) to /psql-backup.sql.gz...'
  assert_output --partial 'ok'

  run restore psql postgres-restore-test /psql-backup.sql.gz
  assert_success
  assert_output --partial 'restoring postgres-restore-test (psql) from /psql-backup.sql.gz...'
  assert_output --partial 'ok'

  psql_datacheck_full
}

@test "backup db_flags work" {
  PG_DUMP_OPTIONS='-T bank' run backup psql postgres-backup-test /psql-backup.sql.gz
  assert_success
  assert_output --partial 'backing up postgres-backup-test (psql) to /psql-backup.sql.gz...'
  assert_output --partial 'ok'

  run restore psql postgres-restore-test /psql-backup.sql.gz
  assert_success
  assert_output --partial 'restoring postgres-restore-test (psql) from /psql-backup.sql.gz...'
  assert_output --partial 'ok'

  TEST_DB_PASS=$TEST_DB_RESTORE_PASS TEST_DB_HOST=$TEST_DB_RESTORE_HOST TEST_DB_USER=$TEST_DB_RESTORE_USER TEST_DB_NAME=$TEST_DB_RESTORE_NAME psql_datacheck_skip_bank
}

@test "restore db_flags work" {
  run backup psql postgres-backup-test /psql-backup.sql.gz
  assert_success
  assert_output --partial 'backing up postgres-backup-test (psql) to /psql-backup.sql.gz...'
  assert_output --partial 'ok'

  PG_RESTORE_OPTIONS='--help' run restore psql postgres-restore-test /psql-backup.sql.gz
  assert_failure
  assert_output --partial 'pg_restore: unrecognized option: help'

}
