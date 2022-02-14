FROM ubuntu:20.04 as builder
WORKDIR /usr/src
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libc6-lse build-essential libz-dev libssl-dev unzip
ADD https://github.com/kinvolk/wrk2/archive/master.zip .
RUN unzip master.zip && \
    cd wrk2-master && \
    make -j && \
    strip wrk

FROM benchmark-base
MAINTAINER Kinvolk

# wrk2
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libc6-lse  libssl1.1 libgcc-s1
COPY --from=builder /usr/src/wrk2-master/wrk /usr/local/bin/
ADD body-100-report.lua /usr/local/share/wrk2/body-100-report.lua

# nginx serving 404 on port 9000 running as benchmark user (switches if started as root)
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libc6-lse  nginx
RUN useradd -m -u 1000 benchmark
RUN sed -i 's/user www-data;/user benchmark;/g' /etc/nginx/nginx.conf
RUN sed -i 's/80 default_server/9000 default_server/g' /etc/nginx/sites-available/default
RUN mkdir /run/nginx
RUN chown benchmark:benchmark -R /var/lib/nginx /run/nginx/ /var/log/nginx

# Runnable scripts
COPY run-benchmark.sh /usr/local/bin/run-benchmark.sh
COPY run-server.sh /usr/local/bin/run-server.sh
