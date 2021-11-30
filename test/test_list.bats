function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  load 'test_helper/common'
  _common_setup

  TEST_DATASTORE_BUCKET=datastore-backup-test
  VCAP_SERVICES="$(cat $(test_fixture mysql-test.vcap.json))"

  aws_helper s3api create-bucket --bucket $TEST_DATASTORE_BUCKET
}

function teardown () {
  # Delete the test bucket
  aws_helper s3 rb s3://$TEST_DATASTORE_BUCKET --force
}

@test "list given an empty bucket succeeds" {
  VCAP_SERVICES="$VCAP_SERVICES" DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3 run list
  assert_success
  refute_output  # No output for an empty bucket
}

@test "list given a single file succeeds with file listing" {
  # Create a test file of size 1337
  truncate -s 1337 $BATS_TEST_DIRNAME/test-file
  aws_helper s3 cp $BATS_TEST_DIRNAME/test-file s3://$TEST_DATASTORE_BUCKET/test-file
  VCAP_SERVICES="$VCAP_SERVICES" DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3 run list
  assert_success
  assert_output --partial "1337 test-file"
}

@test "list given a path with starting slash succeeds with dir listing" {
  # Create a test file of size 1337
  truncate -s 1337 $BATS_TEST_DIRNAME/test-file
  aws_helper s3 cp $BATS_TEST_DIRNAME/test-file s3://$TEST_DATASTORE_BUCKET/test-directory/test-file
  VCAP_SERVICES="$VCAP_SERVICES" DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3 run list /test-directory/
  assert_success
  assert_output --partial "1337 test-file"
}

@test "list given a path without starting slash succeeds with dir listing" {
  # Create a test file of size 1337
  truncate -s 1337 $BATS_TEST_DIRNAME/test-file
  aws_helper s3 cp $BATS_TEST_DIRNAME/test-file s3://$TEST_DATASTORE_BUCKET/test-directory/test-file
  VCAP_SERVICES="$VCAP_SERVICES" DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3 run list test-directory/
  assert_success
  assert_output --partial "1337 test-file"
}
