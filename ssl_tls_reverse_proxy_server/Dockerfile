FROM nginx:alpine

COPY nginx/nginx.conf /etc/nginx/nginx.conf

RUN apk add --no-cache certbot

CMD ["/bin/sh", "-c", "nginx -g 'daemon off;'"]
#CMD ["/bin/sh" , "-c" , "envsubst < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf && exec nginx -g 'daemon off;'"]