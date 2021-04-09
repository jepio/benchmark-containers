#!/bin/bash

set -xeuo pipefail

source /root/venv/bin/activate

cd /root/benchmark
exec pytest test_bench.py $@
