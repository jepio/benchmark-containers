# This container is the basis for all the other benchmark containers.

FROM ubuntu:20.04
MAINTAINER Kinvolk

# dstat
COPY --from=dstat-builder /dstat/dstat /usr/local/bin
COPY --from=dstat-builder /dstat/plugins /usr/local/bin/

# lscpu
RUN apt-get update && apt-get install libc6-lse  util-linux

# Common script
COPY cpu.sh /usr/local/bin/cpu.sh
COPY output.sh /usr/local/bin/output.sh
