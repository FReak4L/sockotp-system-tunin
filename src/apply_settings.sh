#!/bin/bash

source /src/config.sh

apply_best_settings() {
    read -r _ cc qdisc tc rtt loss jitter throughput syn_time <<< "$1"
    
    TCPMAXSEG=$(ip link show $INTERFACE | awk '/mtu/ {print $5-40}')
    TCP_FAST_OPEN=3
    KEEP_ALIVE_INTERVAL=$(echo "scale=0; $rtt / 1000" | bc)
    KEEP_ALIVE_IDLE=$(echo "scale=0; $KEEP_ALIVE_INTERVAL * 10" | bc)
    TCP_USER_TIMEOUT=$(echo "scale=0; $rtt * 3" | bc)
    TCP_CONGESTION=$cc
    WINDOW_CLAMP=$(echo "scale=0; $throughput * 1000 * $rtt / 8" | bc)
    
    sysctl -w net.ipv4.tcp_congestion_control=$TCP_CONGESTION
    sysctl -w net.ipv4.tcp_fastopen=$TCP_FAST_OPEN
    sysctl -w net.ipv4.tcp_keepalive_time=$KEEP_ALIVE_IDLE
    sysctl -w net.ipv4.tcp_keepalive_intvl=$KEEP_ALIVE_INTERVAL
    sysctl -w net.ipv4.tcp_keepalive_probes=3
    sysctl -w net.ipv4.tcp_user_timeout=$TCP_USER_TIMEOUT
    sysctl -w net.ipv4.tcp_window_scaling=1
    sysctl -w net.core.rmem_max=$WINDOW_CLAMP
    sysctl -w net.core.wmem_max=$WINDOW_CLAMP
    sysctl -w net.ipv4.tcp_rmem="4096 87380 $WINDOW_CLAMP"
    sysctl -w net.ipv4.tcp_wmem="4096 87380 $WINDOW_CLAMP"
    sysctl -w net.ipv4.tcp_mtu_probing=1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0
    sysctl -w net.ipv4.tcp_tw_reuse=1
    sysctl -w net.ipv4.tcp_max_syn_backlog=8192
    sysctl -w net.ipv4.tcp_synack_retries=2
    sysctl -w net.ipv4.tcp_syn_retries=2
    sysctl -w net.ipv4.tcp_max_tw_buckets=2000000
    sysctl -w net.ipv4.tcp_fin_timeout=10
    sysctl -w net.core.netdev_max_backlog=16384
    sysctl -w net.ipv4.tcp_notsent_lowat=16384
    sysctl -w net.ipv4.tcp_no_metrics_save=1
    sysctl -w net.ipv4.tcp_moderate_rcvbuf=1
    sysctl -w net.ipv4.tcp_timestamps=1
    sysctl -w net.ipv4.tcp_sack=1
    sysctl -w net.ipv4.tcp_fack=1
    sysctl -w net.ipv4.tcp_ecn=1
    sysctl -w net.ipv4.tcp_dsack=1
    sysctl -w net.ipv4.tcp_low_latency=1
    sysctl -w net.ipv4.ip_no_pmtu_disc=0
    sysctl -w net.ipv4.tcp_adv_win_scale=2
    sysctl -w net.ipv4.tcp_rfc1337=1
    sysctl -w net.ipv4.tcp_abort_on_overflow=0
    sysctl -w net.ipv4.tcp_thin_linear_timeouts=1
    sysctl -w net.ipv4.tcp_limit_output_bytes=262144

    if [ -f /proc/sys/net/mptcp/enabled ]; then
        sysctl -w net.mptcp.enabled=1
        sysctl -w net.mptcp.checksum_enabled=1
    fi

    tc qdisc replace dev $INTERFACE root $qdisc
    [ "$tc" != "none" ] && tc qdisc add dev $INTERFACE root netem $tc

    ip route change default via $(ip route | awk '/default/ {print $3}') dev $INTERFACE proto static initcwnd 10 initrwnd 10 advmss $TCPMAXSEG rto_min 1000 quickack 1

    echo "Applied TCP settings:"
    echo "tcpMaxSeg = $TCPMAXSEG"
    echo "tcpFastOpen = $TCP_FAST_OPEN"
    echo "tcpKeepAliveInterval = $KEEP_ALIVE_INTERVAL"
    echo "tcpKeepAliveIdle = $KEEP_ALIVE_IDLE"
    echo "tcpUserTimeout = $TCP_USER_TIMEOUT"
    echo "tcpcongestion = \"$TCP_CONGESTION\""
    echo "windowClamp = $WINDOW_CLAMP"
    echo "Queueing Discipline: $qdisc"
    echo "TC Settings: $tc"
}
