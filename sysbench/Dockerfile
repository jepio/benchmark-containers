FROM ubuntu:20.04 as builder
WORKDIR /sysbench
MAINTAINER Kinvolk
ENV SYSBENCH_VER=1.0.17
ADD https://github.com/akopytov/sysbench/archive/${SYSBENCH_VER}.tar.gz .
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libc6-lse build-essential git linux-headers-generic automake autoconf libtool libaio-dev libssl-dev libunwind-dev libmariadb-dev-compat pkg-config
RUN tar -xf ${SYSBENCH_VER}.tar.gz && \
	cd sysbench-${SYSBENCH_VER} && \
	export TARGET_LIBS=-lunwind;./autogen.sh && \
	./configure && \
	make -j && \
	make DESTDIR=/sysbench/sysbench-install-root/ install

FROM benchmark-base
MAINTAINER Kinvolk

# sysbench
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libc6-lse  libgcc-s1 libmariadb3 libaio1
COPY --from=builder /sysbench/sysbench-install-root/ /

# Runnable scripts
COPY run-benchmark.sh /usr/local/bin/run-benchmark.sh
