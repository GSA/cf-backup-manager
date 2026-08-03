# s3 integration tests

function setup () {
  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'
  load 'test_helper/common'
  _common_setup

  TEST_DATASTORE_BUCKET=datastore-backup-test
  TEST_SOURCE_BUCKET=application-s3-test
  TEST_RESTORE_BUCKET=application-s3-restore-test
  DATASTORE_S3_SERVICE_NAME=datastore-backup-test-s3
  VCAP_SERVICES="$(cat $(test_fixture s3-test.vcap.json))"
  VCAP_APPLICATION="$(cat $(test_fixture vcap-application.json))"

  export DATASTORE_S3_SERVICE_NAME

  aws_helper s3api create-bucket --bucket $TEST_DATASTORE_BUCKET
  aws_helper s3api create-bucket --bucket $TEST_SOURCE_BUCKET
  aws_helper s3api create-bucket --bucket $TEST_RESTORE_BUCKET
}

function teardown () {
  aws_helper s3 rb s3://$TEST_DATASTORE_BUCKET --force
  aws_helper s3 rb s3://$TEST_SOURCE_BUCKET --force
  aws_helper s3 rb s3://$TEST_RESTORE_BUCKET --force
}

function seed_source_bucket () {
  mkdir -p "$BATS_TEST_TMPDIR/nested"
  printf 'alpha' > "$BATS_TEST_TMPDIR/file.txt"
  printf 'beta' > "$BATS_TEST_TMPDIR/nested/file.txt"

  aws_helper s3 cp "$BATS_TEST_TMPDIR/file.txt" s3://$TEST_SOURCE_BUCKET/file.txt
  aws_helper s3 cp "$BATS_TEST_TMPDIR/nested/file.txt" s3://$TEST_SOURCE_BUCKET/nested/file.txt
}

@test "backup s3 application-s3-test" {
  seed_source_bucket

  run backup s3 application-s3-test /s3-backup

  assert_success
  assert_output --partial 'backing up application-s3-test (s3) to /s3-backup...'
  assert_output --partial 'verified 2 object(s) in s3 backup'
  assert_output --partial 'ok'

  run aws_helper s3 cp s3://$TEST_DATASTORE_BUCKET/s3-backup/file.txt -
  assert_success
  assert_output 'alpha'

  run aws_helper s3 cp s3://$TEST_DATASTORE_BUCKET/s3-backup/nested/file.txt -
  assert_success
  assert_output 'beta'
}

@test "backup s3 uses configured backup prefix" {
  seed_source_bucket

  BACKUP_PREFIX=custom-backups run backup s3 application-s3-test

  assert_success
  assert_output --partial 'backing up application-s3-test (s3) to /custom-backups/development/application-s3-test/application-s3-test-'
  assert_output --partial 'verified 2 object(s) in s3 backup'

  run aws_helper s3 ls s3://$TEST_DATASTORE_BUCKET/custom-backups/development/application-s3-test/ --recursive

  assert_success
  assert_output --partial 'file.txt'
}

@test "backup s3 refuses datastore bucket" {
  run backup s3 datastore-backup-test-s3 /backup-bucket-copy

  assert_failure
  assert_output --partial 'refusing to back up datastore bucket datastore-backup-test'
}

@test "backup s3 fails when source service is not bound" {
  run backup s3 missing-s3 /missing-backup

  assert_failure
  assert_output --partial 'missing-s3 does not exist in vcap_services'
}

@test "restore s3 application-s3-restore-test" {
  mkdir -p "$BATS_TEST_TMPDIR/nested"
  printf 'alpha' > "$BATS_TEST_TMPDIR/file.txt"
  printf 'beta' > "$BATS_TEST_TMPDIR/nested/file.txt"

  aws_helper s3 cp "$BATS_TEST_TMPDIR/file.txt" s3://$TEST_DATASTORE_BUCKET/s3-backup/file.txt
  aws_helper s3 cp "$BATS_TEST_TMPDIR/nested/file.txt" s3://$TEST_DATASTORE_BUCKET/s3-backup/nested/file.txt

  run restore s3 application-s3-restore-test /s3-backup

  assert_success
  assert_output --partial 'restoring application-s3-restore-test (s3) from /s3-backup...'
  assert_output --partial 'ok'

  run aws_helper s3 cp s3://$TEST_RESTORE_BUCKET/file.txt -
  assert_success
  assert_output 'alpha'

  run aws_helper s3 cp s3://$TEST_RESTORE_BUCKET/nested/file.txt -
  assert_success
  assert_output 'beta'
}
