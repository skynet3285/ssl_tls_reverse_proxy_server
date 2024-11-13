docker-compose run --rm -p 8080:80 -d --name temp-certbot-nginx --entrypoint \
    "nginx -g 'daemon off;'" ssl-tls-certbot

docker-compose run --rm --entrypoint --name init-certbot "\
    certbot certonly \
    -d {YOUR_DOMAIN} \
    --email {YOUR_EMAIL} \
    --manual --preferred-challenges http \
    --server https://acme-v02.api.letsencrypt.org/directory \
    --force-renewal" ssl-tls-certbot
echo

docker rm -f temp-certbot-nginx
