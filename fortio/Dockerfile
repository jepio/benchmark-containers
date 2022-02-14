FROM golang:alpine as builder
RUN go get fortio.org/fortio

FROM benchmark-base
MAINTAINER Kinvolk

# fortio
COPY --from=builder /go/bin/fortio /usr/local/bin/fortio

# The benchmark uses jq to parse the JSON output
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y libc6-lse  jq

# Runnable scripts
COPY run-benchmark.sh /usr/local/bin/run-benchmark.sh
COPY run-server.sh /usr/local/bin/run-server.sh
