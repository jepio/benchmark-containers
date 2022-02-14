FROM ubuntu:20.04 as builder
WORKDIR /stress-ng
MAINTAINER Kinvolk
ENV STRESS_VER=0.10.07
ADD https://github.com/ColinIanKing/stress-ng/archive/V${STRESS_VER}.tar.gz .
RUN apt-get update && apt-get install libc6-lse build-essential git linux-headers
RUN tar -xf V${STRESS_VER}.tar.gz && \
	cd stress-ng-${STRESS_VER} && \
	STATIC=1 make -j &&\
	mv stress-ng /stress-ng/

FROM benchmark-base
MAINTAINER Kinvolk

# stress-ng
COPY --from=builder /stress-ng/stress-ng /sbin/

# Runnable scripts
COPY run-benchmark.sh /usr/local/bin/run-benchmark.sh
