function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/common'
  _common_setup

  TEST_DATASTORE_BUCKET=datastore-backup-test
  VCAP_SERVICES="$(cat $(test_fixture mysql-test.vcap.json))"

  # Create the bucket
  aws_helper s3api create-bucket --bucket $TEST_DATASTORE_BUCKET
}

function teardown () {
  # Delete the test bucket
  aws_helper s3 rb s3://$TEST_DATASTORE_BUCKET --force
}

@test "backup mysql" {
  skip
  VCAP_SERVICES="$VCAP_SERVICES" DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3 run backup_restore.sh backup mysql application-db
  assert_success
}
