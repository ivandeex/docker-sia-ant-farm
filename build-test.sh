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
    --tag sia-ant-farm-image \
    -f $DIR/Dockerfile \
    .

  export DUMMY_DATA_DIR=$(mktemp -d)

  # Run container in detached state
  docker run \
    --detach \
    --publish 127.0.0.1:9988:9980 \
    --volume "${DUMMY_DATA_DIR}:/sia-antfarm/antfarm-data" \
    --name sia-ant-farm-test-container \
    sia-ant-farm-image

  # Wait till consensus folder appears
  timeout=120
  while [ ! -e "${DUMMY_DATA_DIR}/renter/consensus" ];
  do
    # When the timeout is equal to zero, show an error and leave the loop.
    if [ "$timeout" == 0 ]; then
        echo "ERROR: Couldn't find consensus folder for image at $DIR"
        docker logs sia-ant-farm-test-container
        docker rm -f sia-ant-farm-test-container
        exit 1
    fi

    sleep 1

    # Decrease the timeout of one
    ((timeout--))
  done

  echo "Created consensus folder successfully"

  curl -A "Sia-Agent" --fail "http://localhost:9988/consensus"

  docker rm -f sia-ant-farm-test-container
done

cleanup_test_containers