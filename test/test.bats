#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
  load 'test_helper/common'
  _common_setup
}

function docker_run () {
  docker-compose run --rm app "$@"
}

@test "echo" {
  run echo ok
  [ "$output" = "ok" ]
}

@test "backup help" {
  run backup_restore.sh help
  assert_output --partial "Backup and restore utility"
}

@test "backup nonexistant service" {
  DATASTORE_S3_SERVICE_NAME=datastore-backup-s3 run backup_restore.sh backup mysql my-app-db
  assert_failure
  assert_output --partial "my-app-db not found in VCAP_SERVICES."
}
