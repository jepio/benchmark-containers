FROM ubuntu:20.04 as builder
WORKDIR /usr/src
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libc6-lse build-essential libluajit-5.1-dev libssl-dev unzip
ENV WRK_VER=4.2.0
ADD https://github.com/wg/wrk/archive/${WRK_VER}.tar.gz .
RUN tar xf ${WRK_VER}.tar.gz && \
    cd wrk-${WRK_VER} && \
    make -j && \
    strip wrk && \
    mv wrk /usr/src/

FROM benchmark-base
LABEL maintainer="Kinvolk"

# nginx serving 404 on port 8000 running as benchmark user (switches if started as root)
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libc6-lse  nginx curl
COPY --from=builder /usr/src/wrk /usr/local/bin
RUN useradd -m -u 1000 benchmark
RUN sed -i 's/user www-data;/user benchmark;/g' /etc/nginx/nginx.conf
RUN sed -i 's/80 default_server/8000 default_server/g' /etc/nginx/sites-available/default
RUN mkdir /run/nginx

ADD report-json.lua /usr/local/share/wrk/report-json.lua
COPY run-benchmark.sh /usr/local/bin/run-benchmark.sh
RUN chmod 755 /usr/local/bin/run-benchmark.sh

CMD nginx -g "daemon off;"
