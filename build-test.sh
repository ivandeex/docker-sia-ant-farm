#!/bin/bash

## Exit immediately on error.
set -e

# Set function to be called on exit
trap 'exit_err_cleanup $?' EXIT

###############################################################################
# exit_err_cleanup is called at exit, if there was an error it calls container
# cleanup and reports an error.
# Globals: none
# Parameters:
# - $1: Script exit code
###############################################################################
exit_err_cleanup() {
  # Cleanup containers and report an error if any happened
  if [ "$1" != "0" ]; then
    cleanup_test_containers
    echo "ERROR: Error $1 occured"
  else
    echo "SUCCESS: Build and test finished successfully"
  fi

  exit $1
}

###############################################################################
# cleanup_test_containers removes test containers.
# Globals: none
# Parameters: none
###############################################################################
cleanup_test_containers() {
  doing "Removing test containers"
  CONTAINERS=$(docker ps -a -q --filter "name=sia-ant-farm-test-container")
  if [ ! -z $CONTAINERS ]; then
    docker stop $CONTAINERS
    docker rm   $CONTAINERS
  fi
  finished
}

###############################################################################
# doing sets and echoes the given message.
# Globals:
# - DOING_MSG: variable to store the message for finished() function
# Parameters:
# - $1: The message to be set and to be echoed
###############################################################################
doing() {
  DOING_MSG=$1
  echo "$DOING_MSG..."
}

###############################################################################
# finished echoes that the message finished.
# Globals:
# - DOING_MSG: variable to store the message from doing() function
# Parameters: none
###############################################################################
finished() {
  echo "$DOING_MSG finished successfully"
}

###############################################################################
# wait_for_consensus waits for the ant consensus to be reachable.
# Globals: none
# Parameters:
# - $1: Timeout to wait for the consensus
# - $2: API port of the ant to be checked
###############################################################################
wait_for_consensus() {
  # Parameters
  local timeout=$1
  local port=$2
  
  # Set variables
  local url=http://localhost:$port/consensus
  local cmd="until wget --user-agent='Sia-Agent' -q -O - $url
    do
      sleep 1
    done"
  
  # execute
  doing "Waiting for consensus at $url"
  timeout $timeout sh -c "$cmd"
  finished
}

###############################################################################
# wait_for_renter_upload_ready waits until the renter ant is upload ready.
# Globals: none
# Parameters:
# - $1: Timeout to wait for the renter to become upload ready
# - $2: API port of the renter ant to be checked
###############################################################################
wait_for_renter_upload_ready() {
  # Parameters
  local timeout=$1
  local port=$2
  
  # Set variables
  local url=http://localhost:$port/renter/uploadready
  local cmd="until wget --user-agent='Sia-Agent' -q -O - $url | grep '\"ready\":true' 
    do
      sleep 1
    done"
  
  # execute
  doing "Waiting for renter to become upload ready at $url"
  timeout $timeout sh -c "$cmd"
  finished
}

# Remove test containers before we start
cleanup_test_containers

# Iterate over all Dockerfiles
for DIR in ./
do
  # Build the image
  docker build \
    --no-cache \
    --tag sia-ant-farm-image-test \
    -f $DIR/Dockerfile \
    .

  # Test with a single published port
  # Run container in detached state
  DUMMY_DATA_DIR=$(mktemp -d)
  doing "Starting test container"
  docker run \
    --detach \
    --publish 127.0.0.1:9988:9980 \
    --volume "${DUMMY_DATA_DIR}:/sia-antfarm/data" \
    --name sia-ant-farm-test-container \
    sia-ant-farm-image-test
  finished

  # Wait till API (/consensus) is accessible
  wait_for_consensus 120 9988

  # Wait for renter to become upload ready
  wait_for_renter_upload_ready 300 9988

  # Remove test container
  cleanup_test_containers

  # Test with 2 published ports
  # Run container in detached state
  DUMMY_DATA_DIR=$(mktemp -d)
  doing "Starting test container 2"
  docker run \
    --detach \
    --publish 127.0.0.1:9988:9980 \
    --publish 127.0.0.1:10988:10980 \
    --volume "${DUMMY_DATA_DIR}:/sia-antfarm/data" \
    --volume "$(pwd)/config:/sia-antfarm/config" \
    --env CONFIG=config/basic-renter-5-hosts-2-api-ports-docker.json \
    --name sia-ant-farm-test-container \
    sia-ant-farm-image-test
  finished
  
  # Wait till both APIs (/consensus) are accessible
  wait_for_consensus 120 9988
  wait_for_consensus 10 10988
  
  # Wait for renter to become upload ready
  wait_for_renter_upload_ready 300 9988

  # Remove test container
  cleanup_test_containers
done
