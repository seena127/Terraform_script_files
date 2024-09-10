set -e
docker pull bsreenu1999/py-app
docker run -d -p 5000:80 bsreenu1999/py-app
