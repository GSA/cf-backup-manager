# S3 backup bucket retention tests

function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/common'
  _common_setup

  TEST_DATASTORE_BUCKET=datastore-backup-test
  DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3
  VCAP_SERVICES="$(cat $(test_fixture s3-test.vcap.json))"

  export DATASTORE_S3_SERVICE_NAME

  aws_helper s3api create-bucket --bucket $TEST_DATASTORE_BUCKET
}

function teardown () {
  aws_helper s3 rb s3://$TEST_DATASTORE_BUCKET --force
}

@test "retention configures backup bucket lifecycle" {
  run retention 90 backup-manager-v1/development/application-s3-test/

  assert_success
  assert_output --partial 'configured datastore-backup-test retention: expire backup-manager-v1/development/application-s3-test/ after 90 days'

  run aws_helper s3api get-bucket-lifecycle-configuration --bucket $TEST_DATASTORE_BUCKET

  assert_success
  assert_output --partial '"ID": "backup-manager-retention-90-days"'
  assert_output --partial '"Prefix": "backup-manager-v1/development/application-s3-test/"'
  assert_output --partial '"Days": 90'
}
