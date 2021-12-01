_common_setup() {
    # get the containing directory of this file use $BATS_TEST_FILENAME instead
    # of ${BASH_SOURCE[0]} or $0, as those will point to the bats executable's
    # location or the preprocessed file respectively
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/.." >/dev/null 2>&1 && pwd )"
    # make executables in /app/bin visible to PATH
    PATH="$PROJECT_ROOT/bin:$PATH"
}

function test_fixture () {
  echo $BATS_TEST_DIRNAME/data/$1
}

# AWS CLI wrapper for test environment
function aws_helper () {
  AWS_ACCESS_KEY_ID=minio AWS_SECRET_ACCESS_KEY=miniopassword aws --endpoint http://s3:9000 "$@"
}

function wait_for () {
  local -i retries=0
  while [[ $retries -lt 60 ]]; do
    if "$@"; then
      break
    fi

    sleep 1
    retries=$(( $retries + 1))
  done
}
