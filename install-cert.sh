#!/bin/bash

# Check user has specified domain name
if [ -z "$MY_DOMAIN_NAME" ]; then
    echo "Need to set MY_DOMAIN_NAME (to a letsencrypt-registered name)."
    exit 1
fi

if [ ! -d "/etc/letsencrypt/live/$MY_DOMAIN_NAME" ]; then


  # /etc/certbot/certbot-auto certonly --webroot -w /etc/nginx/www -d $MY_DOMAIN_NAME


  # Put your domain name into the nginx reverse proxy config.
  sed -i "s/___my.example.com___/$MY_DOMAIN_NAME/g" /etc/nginx/nginx.conf

  sed -i "s/___LETSENCRYPT_ADDR___/$LETSENCRYPT_ADDR/g" /etc/nginx/nginx.conf
  sed -i "s/___LETSENCRYPT_PORT___/$LETSENCRYPT_PORT/g" /etc/nginx/nginx.conf

  cat /etc/nginx/nginx.conf
  echo .
  echo Firing up nginx in the background.
  nginx

  # This bit waits until the letsencrypt container has done its thing.
  # We see the changes here bceause there's a docker volume mapped.
  echo Waiting for folder /etc/letsencrypt/live/$MY_DOMAIN_NAME to exist
  while [ ! -d /etc/letsencrypt/live/$MY_DOMAIN_NAME ] ;
  do
      sleep 2
  done

  while [ ! -f /etc/letsencrypt/live/$MY_DOMAIN_NAME/fullchain.pem ] ;
  do
  	echo Waiting for file fullchain.pem to exist
      sleep 2
  done

  while [ ! -f /etc/letsencrypt/live/$MY_DOMAIN_NAME/privkey.pem ] ;
  do
  	echo Waiting for file privkey.pem to exist
      sleep 2
  done

  echo replacing ___my.example.com___/$MY_DOMAIN_NAME
  echo replacing ___APPLICATION_IP___/$APP_ADDR
  echo replacing ___APPLICATION_PORT___/$APP_PORT

  # Put your domain name into the nginx reverse proxy config.
  sed -i "s/___my.example.com___/$MY_DOMAIN_NAME/g" /etc/nginx/nginx-with-ssl.conf

  # Add your app's container IP and port into config
  sed -i "s/___APPLICATION_ADDR___/$APP_ADDR/g" /etc/nginx/nginx-with-ssl.conf
  sed -i "s/___APPLICATION_PORT___/$APP_PORT/g" /etc/nginx/nginx-with-ssl.conf


  sed -i "s/___LETSENCRYPT_ADDR___/$LETSENCRYPT_ADDR/g" /etc/nginx/nginx-with-ssl.conf
  sed -i "s/___LETSENCRYPT_PORT___/$LETSENCRYPT_PORT/g" /etc/nginx/nginx-with-ssl.conf

  #go!
  cat /etc/nginx/nginx.conf
  echo .
  echo Killing nginx
  kill $(ps aux | grep '[n]ginx' | awk '{print $2}')


  cp /etc/nginx/nginx-with-ssl.conf /etc/nginx/nginx.conf
fi

echo "Starting nginx in foreground"
exec nginx -g 'daemon off;'
