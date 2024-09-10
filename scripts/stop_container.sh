set -e

cont_id= docker ps | awk '{print $1}'
docker stop $(docker ps -q)

