# Test backup command for mysql services

function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  load 'test_helper/common'
  load 'test_helper/mysql'
  _common_setup

  TEST_DATASTORE_BUCKET=datastore-backup-test
  export DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3

  # Make sure the test fixture contains service credentials that match the
  # docker-compose environment. The backup command will backup from the local
  # mysql container to the local minio s3 service.
  VCAP_SERVICES="$(cat $(test_fixture mysql-test.vcap.json))"
  VCAP_APPLICATION="$(cat $(test_fixture vcap-application.json))"

  aws_helper s3api create-bucket --bucket $TEST_DATASTORE_BUCKET

  # Wait for mysql container to be up
  wait_for mysql_cmd <<SQL
select 1;
SQL
}

function teardown () {
  # Delete the test bucket
  aws_helper s3 rb s3://$TEST_DATASTORE_BUCKET --force
}

@test "backup given no arguments prints usage" {
  run backup
  assert_failure
  assert_output --partial 'usage: backup <service_type> <service_name> [backup_path]'
}

@test "backup mysql application-mysql-db" {
  run backup mysql application-mysql-db
  assert_success
  assert_output --partial "backing up application-mysql-db (mysql) to"
  assert_output --partial "ok"
}
