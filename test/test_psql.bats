# psql integration tests

function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  load 'test_helper/common'
  load 'test_helper/psql'
  _common_setup
  psql_initdb
  TEST_DATASTORE_BUCKET=datastore-backup-test
  export DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3

  VCAP_SERVICES="$(cat $(test_fixture psql-test.vcap.json))"
  VCAP_APPLICATION="$(cat $(test_fixture vcap-application.json))"

  # Create the bucket
  aws_helper s3api create-bucket --bucket $TEST_DATASTORE_BUCKET

  wait_for eval "$psql_cmd -c 'select 1;'"
}

function teardown () {
  psql_cleandb
  # Delete the test bucket
  aws_helper s3 rb s3://$TEST_DATASTORE_BUCKET --force
}

@test "psql init, backup, restore and verify" {
  run backup psql postgres /psql-backup.sql.gz
  assert_success
  assert_output --partial 'backing up postgres (psql) to /psql-backup.sql.gz...'
  assert_output --partial 'ok'

  run restore '--clean' psql postgres /psql-backup.sql.gz
  assert_success
  assert_output --partial 'restoring postgres (psql) from /psql-backup.sql.gz...'
  assert_output --partial 'ok'

  psql_datacheck_full
}

@test "backup db_flags work" {
  run backup '-T bank' psql postgres /psql-backup.sql.gz
  assert_success
  assert_output --partial 'backing up postgres (psql) to /psql-backup.sql.gz...'
  assert_output --partial 'ok'

  run restore '--clean' psql postgres /psql-backup.sql.gz
  assert_success
  assert_output --partial 'restoring postgres (psql) from /psql-backup.sql.gz...'
  assert_output --partial 'ok'

  psql_datacheck_skip_bank
}
