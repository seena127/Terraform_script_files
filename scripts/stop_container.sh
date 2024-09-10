#!/bin/bash

# Get the list of all running containers
containers=$(docker ps -q)

# Check if there are any running containers
if [ -n "$containers" ]; then
  echo "Stopping containers: $containers"
  docker stop $containers
else
  echo "No containers are currently running."
fi
