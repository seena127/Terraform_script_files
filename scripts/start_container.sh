set -e
docker pull bsreenu1999/py-app
img_id= docker images | awk -F'\t' '$2 ~ /latest/ {print $2}'
docker run -d -p 5000:80 $img_id --name sampl-py-app
