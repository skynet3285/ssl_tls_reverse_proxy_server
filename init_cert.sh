docker-compose run --rm --entrypoint "\
    certbot certonly \
    -d {*.YOUR_DOMAIN.COM} \
    --email {YOUR_EMAIL@XXXX.COM} \
    --manual --preferred-challenges dns \
    --server https://acme-v02.api.letsencrypt.org/directory \
    --force-renewal" ssl-certbot
echo

echo "### Reloading nginx ..."
docker-compose exec ssl nginx -s reload