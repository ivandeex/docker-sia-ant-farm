#!/bin/bash

## Exit immediately on error.
set -e

# Echo to console.
set -x

cleanup_test_containers() {
  CONTAINERS=$(docker ps -a -q --filter "name=sia-ant-farm-test-container")
  if [ ! -z $CONTAINERS ]; then
    docker stop $CONTAINERS
    docker rm   $CONTAINERS
  fi
}

cleanup_test_containers

for DIR in ./
do
  docker build \
    --tag sia-ant-farm-image-test \
    -f $DIR/Dockerfile \
    .

  export DUMMY_DATA_DIR=$(mktemp -d)

  # Run container in detached state
  docker run \
    --detach \
    --publish 127.0.0.1:9988:9980 \
    --volume "${DUMMY_DATA_DIR}:/sia-antfarm/antfarm-data" \
    --name sia-ant-farm-test-container \
    sia-ant-farm-image-test

  # Wait till API (/consensus) is accessible
  echo "Get consensus..."
  timeout 120 bash -c 'until curl -A "Sia-Agent" --fail "http://localhost:9988/consensus"; do sleep 1; done'
  echo "Got consensus successfully"

  docker rm -f sia-ant-farm-test-container
done

cleanup_test_containers
