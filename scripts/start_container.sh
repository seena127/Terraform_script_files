#!/bin/bash
set -e

# Pull the Docker image from Docker Hub
docker push bsreenu1999/py-app:latest

# Run the Docker image as a container
docker run -d -p 5000:5000 bsreenu1999/py-app:latest
