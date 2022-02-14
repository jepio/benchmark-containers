FROM ubuntu:20.04 as dstat-builder
MAINTAINER Kinvolk
RUN apt-get update && apt-get install libc6-lse git patch
RUN cd / && git clone https://github.com/dagwieers/dstat.git
COPY ./dstat-types.patch /dstat/dstat-types.patch 
RUN cd /dstat && \
    patch <dstat-types.patch
