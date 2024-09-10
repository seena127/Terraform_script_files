#!/bin/bash
set -e

cont_id= docker ps | awk '{print $1}'
docker stop $cont_id
docker rm -f $cont_id
