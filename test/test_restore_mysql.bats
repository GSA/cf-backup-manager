# Test restore command for mysql services

function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  load 'test_helper/common'
  _common_setup

  TEST_DATASTORE_BUCKET=datastore-backup-test
  export DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3

  # Make sure the test fixture contains service credentials that match the
  # docker-compose environment. The backup command will backup from the local
  # mysql container to the local minio s3 service.
  VCAP_SERVICES="$(cat $(test_fixture mysql-test.vcap.json))"
  VCAP_APPLICATION="$(cat $(test_fixture vcap-application.json))"

  aws_helper s3api create-bucket --bucket $TEST_DATASTORE_BUCKET
  # upload backup fixture
}

function teardown () {
  # Delete the test bucket
  aws_helper s3 rb s3://$TEST_DATASTORE_BUCKET --force
}

@test "restore given no arguments prints usage" {
  run restore
  assert_failure
  assert_output --partial 'usage: restore <service_type> <service_name> <backup_path>'
}

@test "restore mysql application-db" {
  run restore mysql application-db /mysql-backup.sql.gz
  assert_success
  assert_output --partial 'usage: restore <service_type> <service_name> [path]'
}
