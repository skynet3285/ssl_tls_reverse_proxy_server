FROM nginx:alpine

RUN apk add --no-cache certbot
COPY nginx.conf /etc/nginx/nginx.conf

CMD ["/bin/sh", "-c", "nginx -g 'daemon off;' & trap exit TERM; while :; do certbot renew --webroot --webroot-path=/var/www/certbot --preferred-challenges http; sleep 12h & wait $${!}; done;"]
