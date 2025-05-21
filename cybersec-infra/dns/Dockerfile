FROM ubuntu/bind9:latest

RUN apt-get update && apt-get install -y bind9utils

EXPOSE 53/tcp
EXPOSE 53/udp

CMD ["/usr/sbin/named", "-g", "-c", "/etc/bind/named.conf", "-u", "bind"]