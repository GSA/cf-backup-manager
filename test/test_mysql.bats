
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

TEST_DATASTORE_BUCKET=datastore-backup-test

function setup () {
  load 'test_helper/common'
  _common_setup

  VCAP_SERVICES="$(cat $(test_fixture mysql-test.vcap.json))"
  AWS_ACCESS_KEY_ID=minio AWS_SECRET_ACCESS_KEY=miniopassword aws --endpoint http://s3:9000 s3api create-bucket --bucket $TEST_DATASTORE_BUCKET
}

function teardown () {
  # Delete the test bucket
  AWS_ACCESS_KEY_ID=minio AWS_SECRET_ACCESS_KEY=miniopassword aws --endpoint http://s3:9000 s3 rb s3://$TEST_DATASTORE_BUCKET --force
}

@test "backup mysql" {
  VCAP_SERVICES="$VCAP_SERVICES" DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3 run backup_restore.sh backup mysql application-db
  assert_success
}
