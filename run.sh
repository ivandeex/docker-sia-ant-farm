#!/bin/sh

# We are using socat in order ant API to be accessible outside of docker
# container.
socat tcp-listen:9980,reuseaddr,fork tcp:localhost:10980 &

# We are using `exec` to start Sia Ant Farm in order to ensure that it will be
# run as PID 1. We need that in order to have Sia Ant Farm receive OS signals
# (e.g. SIGTERM) on container shutdown, so it can exit gracefully.
exec sia-antfarm -config=${CONFIG}