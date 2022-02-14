FROM ubuntu:20.04 as builder
WORKDIR /fio
ENV FIO_VER=3.15
ADD https://github.com/axboe/fio/archive/fio-${FIO_VER}.tar.gz .
RUN apt-get update && apt-get install libc6-lse build-essential libaio-dev zlib-dev linux-headers coreutils
RUN tar xzf fio-${FIO_VER}.tar.gz && \
    cd fio-fio-${FIO_VER} && \
    ./configure && \
    make -j && \
    strip fio && \
    mv fio /fio/


FROM ubuntu:20.04
MAINTAINER Kinvolk
# dstat
RUN apt-get update && apt-get install libc6-lse  py2-six
COPY --from=dstat-builder /dstat/dstat /usr/local/bin
COPY --from=dstat-builder /dstat/plugins /usr/local/bin/
# fio
RUN apt-get update && apt-get install libc6-lse  util-linux libaio zlib so:libgcc_s.so.1
COPY --from=builder /fio/fio /usr/local/bin
