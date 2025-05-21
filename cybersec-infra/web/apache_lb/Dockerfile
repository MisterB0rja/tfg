FROM httpd:latest

RUN apt-get update && \
    apt-get install -y libapache2-mod-proxy-html libxml2-dev && \
    a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests

COPY httpd.conf /usr/local/apache2/conf/httpd.conf
COPY extra/httpd-vhosts.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf

EXPOSE 80