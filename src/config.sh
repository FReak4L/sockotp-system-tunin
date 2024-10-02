#!/bin/bash

DESTINATIONS=(
    "8.8.8.8"
    "1.1.1.1"
    "www.github.com"
)

IPERF_SERVERS=(
    "gra.proof.ovh.net"
)

CONGESTION_CONTROLS=("cubic" "bbr" "reno")
QUEUEING_DISCIPLINES=("fq" "fq_codel" "cake" "pfifo_fast")
TC_SETTINGS=("none" "delay 50ms" "loss 1%" "rate 100mbit")

# Test variables
TEST_ITERATIONS=5
TEST_DURATION=10
PING_COUNT=100

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Network interface
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -n1)
