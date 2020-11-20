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

###############################################################################
# Echo curl loop string to be used in 'timeout' command. The string when
# executed executes curl command with the given url in the loop untill the curl
# executes successfully.
# Globals:
#   none
# Parameters:
#   url, e.g.: http://localhost:9988/consensus
# Outputs:
#   Echoes curl loop string
###############################################################################
curl_loop() {
  local url=$1
  echo "until curl -A \"Sia-Agent\" --fail $url
    do
      sleep 1
    done"
}

cleanup_test_containers

for DIR in ./
do
  docker build \
    --no-cache \
    --tag sia-ant-farm-image-test \
    -f $DIR/Dockerfile \
    .

  export DUMMY_DATA_DIR=$(mktemp -d)

  # Test with a single published port
  # Run container in detached state
  docker run \
    --detach \
    --publish 127.0.0.1:9988:9980 \
    --volume "${DUMMY_DATA_DIR}:/sia-antfarm/data" \
    --name sia-ant-farm-test-container \
    sia-ant-farm-image-test

  # Wait till API (/consensus) is accessible
  echo "Get consensus..."
  curl_loop=$(curl_loop "http://localhost:9988/consensus")
  timeout 120 sh -c "$curl_loop"
  echo "Got consensus successfully"

  docker rm -f sia-ant-farm-test-container

  # Test with 2 published ports
  docker run \
    --detach \
    --publish 127.0.0.1:9988:9980 \
    --publish 127.0.0.1:10988:10980 \
    --volume "${DUMMY_DATA_DIR}:/sia-antfarm/data" \
    --volume "$(pwd)/config:/sia-antfarm/config" \
    --env CONFIG=config/basic-renter-5-hosts-2-api-ports-docker.json \
    --name sia-ant-farm-test-2-apis-container \
    sia-ant-farm-image-test
  
  # Wait till both APIs (/consensus) are accessible
  echo "Get consensus..."
  curl_loop2=$(curl_loop "http://localhost:10988/consensus")
  timeout 120 sh -c "$curl_loop" && timeout 10 sh -c "$curl_loop2"
  echo "Got consensus successfully"

  docker rm -f sia-ant-farm-test-2-apis-container
done

cleanup_test_containers
