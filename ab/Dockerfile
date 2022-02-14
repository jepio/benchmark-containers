FROM benchmark-base
MAINTAINER Kinvolk

# ab
RUN apt-get update && apt-get install libc6-lse  apache2-utils

# nginx serving 404 on port 8000 running as benchmark user (switches if started as root)
RUN apt-get update && apt-get install libc6-lse  nginx
RUN adduser -u 1000 -D benchmark
RUN sed -i 's/user nginx;/user benchmark;/g' /etc/nginx/nginx.conf
RUN sed -i 's/80 default_server/8000 default_server/g' /etc/nginx/conf.d/default.conf
RUN mkdir /run/nginx
RUN chown benchmark:benchmark -R /var/lib/nginx /run/nginx/ /var/log/nginx

# Runnable scripts
COPY run-benchmark.sh /usr/local/bin/run-benchmark.sh
COPY run-server.sh /usr/local/bin/run-server.sh
