#!/bin/bash

DESTINATIONS=(
    "www.github.com"
)

IPERF_SERVERS=(
    "gra.proof.ovh.net"
)

CONGESTION_CONTROLS=("cubic" "bbr")
QUEUEING_DISCIPLINES=("fq_codel" "cake")
TC_SETTINGS=("none" "loss 1%")

# Test variables
TEST_ITERATIONS=3
TEST_DURATION=5
PING_COUNT=30

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Network interface
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
