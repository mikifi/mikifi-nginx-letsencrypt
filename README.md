# Introduction #

Using the mikifi/nginx-letsencrypt Docker image you can easily configure a
nginx https reverse proxy in front of a backend service. Used together with
the quay.io/letsencrypt/letsencrypt image, the SSL certificate for
the  given domain can be installed and refreshed more or less automatically.

The approach used are a combination of the solutions described by these resources:
1. http://www.automationlogic.com/using-lets-encrypt-and-docker-for-automatic-ssl/
2. https://manas.tech/blog/2016/01/25/letsencrypt-certificate-auto-renewal-in-docker-powered-nginx-reverse-proxy.html
3. https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion

# How to use it #

One way to use this nginx reverse proxy Docker image is to use docker-compose to
combine this image with the letsencrypt image and your backend service image.

## Docker Compose ##

Your docker-compose.yml might look something like:


```yml
version: '2'
services:
  beehive:
    image: my-backend-image:latest
    container_name: mybackend
    mem_limit: 1G
    expose:
      - "8080"
    networks:
      - mynetwork

  nginx:
    image: mikifi/nginx-letsencrypt:latest
    container_name: nginx
    mem_limit: 64M
    environment:
      - MY_DOMAIN_NAME=<my domain>
      - APP_ADDR=mybackend
      - APP_PORT=8080
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - /var/www:/var/www:ro
      - /root/api-users.htaccess:/etc/nginx/api-users.htaccess:ro
      - /etc/nginx
    ports:
      - "80:80"
      - "443:443"
    links:
      - mybackend
      - letsencrypt
    networks:
      - mynetwork

  letsencrypt:
    image: quay.io/letsencrypt/letsencrypt:latest
    container_name: letsencrypt
    mem_limit: 128M
    command:  bash -c "sleep 6 && certbot certonly --webroot -w /var/www/ -d <my domain> --agree-tos --email <email address> --verbose --keep-until-expiring"
    entrypoint: ""
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt
      - /var/lib/letsencrypt:/var/lib/letsencrypt
      - /var/www:/var/www
    environment:
      - TERM=xterm

networks:
  mynetwork:
    driver: bridge
```

The environment variables MY_DOMAIN_NAME, APP_ADDR and APP_PORT must be set.
Also the letsencrypt command must be edited with your email and domain name.

## Letsencrypt certificate ##

The letsencrypt image are using the webroot domain verification method through the
nginx reverse proxy (port 80). If there is no certificate installed, a new
certificate will be created for the given domain. If there already exists a
certificate, it will be renewed if it expires within the next month.

## Renew certificate with cron ##

When you start these images with docker-compose, the letsencrypt container will
run only once (either creating or renewing the certificate). In order to
renew the letsencrypt certificate (it will expire after 90 days),
you need to re-run the container periodically.

To run it weekly, add this script to the /etc/cron.weekly/ folder (assuming the
  docker-compose and docker commands are in your path):

```sh
#!/bin/sh

docker-compose start letsencrypt
sleep 180
docker kill -s HUP nginx
```

The last command reloads the nginx config (and the new certificate).

## Authentication

You must edit the nginx-with-ssl.conf with whatever authentication setup
you are using.
