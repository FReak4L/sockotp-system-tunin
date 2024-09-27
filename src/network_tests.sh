#!/bin/bash

source /src/config.sh

perform_network_tests() {
    local dest=$1 cc=$2 qdisc=$3 tc_setting=$4
    local results=()

    trap 'tc qdisc del dev $INTERFACE root >/dev/null 2>&1 || true' EXIT

    sysctl -w net.ipv4.tcp_congestion_control=$cc >/dev/null 2>&1 || { echo "Failed to set CC: $cc"; return 1; }
    tc qdisc replace dev $INTERFACE root $qdisc >/dev/null 2>&1 || { echo "Failed to set QDISC: $qdisc"; return 1; }
    [ "$tc_setting" != "none" ] && tc qdisc add dev $INTERFACE root netem $tc_setting >/dev/null 2>&1

    for _ in $(seq 1 $TEST_ITERATIONS); do
        ping_result=$(ping -c $PING_COUNT -q $dest 2>/dev/null) || { echo "Ping failed for $dest"; continue; }
        rtt=$(echo "$ping_result" | awk -F'/' 'END {print $5}')
        loss=$(echo "$ping_result" | awk -F'%' '{print $1}' | awk '{print $NF}')
        jitter=$(echo "$ping_result" | awk -F'/' 'END {print $7}')

        syn_time=$(/src/tcp_connect_time $dest 80 2>/dev/null) || { echo "SYN measurement failed for $dest"; continue; }

        iperf_server=${IPERF_SERVERS[$RANDOM % ${#IPERF_SERVERS[@]}]}
        iperf_result=$(iperf3 -c $iperf_server -t $TEST_DURATION -J 2>/dev/null) || { echo "iperf3 failed for $iperf_server"; continue; }
        throughput=$(echo "$iperf_result" | jq -r '.end.sum_received.bits_per_second / 1e6')

        results+=("$rtt $loss $jitter $throughput $syn_time")
        sleep 2
    done

    [ "$tc_setting" != "none" ] && tc qdisc del dev $INTERFACE root >/dev/null
    [ ${#results[@]} -eq 0 ] && { echo "No valid results for $dest"; return 1; }
    
    local avg_rtt avg_loss avg_jitter avg_throughput avg_syn_time
    avg_rtt=$(echo "${results[@]}" | awk '{sum+=$1} END {print sum/NR}')
    avg_loss=$(echo "${results[@]}" | awk '{sum+=$2} END {print sum/NR}')
    avg_jitter=$(echo "${results[@]}" | awk '{sum+=$3} END {print sum/NR}')
    avg_throughput=$(echo "${results[@]}" | awk '{sum+=$4} END {print sum/NR}')
    avg_syn_time=$(echo "${results[@]}" | awk '{sum+=$5} END {print sum/NR}')

    echo "$avg_rtt $avg_loss $avg_jitter $avg_throughput $avg_syn_time"
}
