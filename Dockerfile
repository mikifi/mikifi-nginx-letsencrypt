FROM nginx:1.11.10-alpine

RUN apk update
RUN apk add openssl
RUN apk add bash
RUN openssl dhparam -out /etc/nginx/dhparams.pem 2048

COPY nginx.conf /etc/nginx/
COPY nginx-with-ssl.conf /etc/nginx/
COPY install-cert.sh /etc/nginx/
RUN chmod +x /etc/nginx/install-cert.sh

# default command
CMD ["/bin/bash", "-c", "/etc/nginx/install-cert.sh"]
