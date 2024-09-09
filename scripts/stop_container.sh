set -e
cont_id= docker ps | awk -F" " '{print $1}'
docker stop $cont_id
docker rm $cont_id
