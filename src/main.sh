#!/bin/bash

#Dir
cd "$(dirname "$0")"

source ./config.sh
source ./network_tests.sh
source ./optimization.sh
source ./apply_settings.sh

check_dependencies() {
    command -v iperf3 >/dev/null 2>&1 || { echo >&2 "iperf3 is required but not installed. Aborting."; exit 1; }
    command -v tc >/dev/null 2>&1 || { echo >&2 "tc is required but not installed. Aborting."; exit 1; }
    command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but not installed. Aborting."; exit 1; }
}

main() {
    check_dependencies

    echo -e "${YELLOW}Starting network optimization...${NC}"
    echo -e "${YELLOW}Current network settings:${NC}"
    sysctl -a | grep -E 'tcp_congestion_control|tcp_rmem|tcp_wmem|tcp_fastopen|tcp_tw_reuse|mptcp|tcp_max_syn_backlog|tcp_synack_retries|tcp_syn_retries|tcp_max_tw_buckets|tcp_fin_timeout|netdev_max_backlog|tcp_keepalive|tcp_user_timeout|tcp_window_scaling|tcp_mtu_probing|tcp_slow_start_after_idle|tcp_notsent_lowat|tcp_no_metrics_save|tcp_moderate_rcvbuf|tcp_timestamps|tcp_sack|tcp_fack|tcp_ecn|tcp_dsack|tcp_low_latency|ip_no_pmtu_disc|tcp_adv_win_scale|tcp_rfc1337|tcp_abort_on_overflow|tcp_thin_linear_timeouts|tcp_limit_output_bytes'
    tc qdisc show dev $INTERFACE
    ip route show default

    best_combo=$(optimize_network)
    
    echo -e "${YELLOW}Applying best settings...${NC}"
    apply_best_settings "$best_combo"

    echo -e "${GREEN}Optimization complete.${NC}"
    echo -e "${YELLOW}Final settings:${NC}"
    sysctl -a | grep -E 'tcp_congestion_control|tcp_rmem|tcp_wmem|tcp_fastopen|tcp_tw_reuse|mptcp|tcp_max_syn_backlog|tcp_synack_retries|tcp_syn_retries|tcp_max_tw_buckets|tcp_fin_timeout|netdev_max_backlog|tcp_keepalive|tcp_user_timeout|tcp_window_scaling|tcp_mtu_probing|tcp_slow_start_after_idle|tcp_notsent_lowat|tcp_no_metrics_save|tcp_moderate_rcvbuf|tcp_timestamps|tcp_sack|tcp_fack|tcp_ecn|tcp_dsack|tcp_low_latency|ip_no_pmtu_disc|tcp_adv_win_scale|tcp_rfc1337|tcp_abort_on_overflow|tcp_thin_linear_timeouts|tcp_limit_output_bytes'
    tc qdisc show dev $INTERFACE
    ip route show default
}

trap 'echo "An error occurred. Exiting..."; exit 1' ERR

main
