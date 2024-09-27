#!/bin/bash

source /src/config.sh
source /src/network_tests.sh

optimize_network() {
    local best_score=0 best_combo=""

    for dest in "${DESTINATIONS[@]}"; do
        for cc in "${CONGESTION_CONTROLS[@]}"; do
            for qdisc in "${QUEUEING_DISCIPLINES[@]}"; do
                for tc in "${TC_SETTINGS[@]}"; do
                    echo -e "${YELLOW}Testing: $dest, $cc, $qdisc, $tc${NC}"
                    result=$(perform_network_tests "$dest" "$cc" "$qdisc" "$tc")
                    [ $? -ne 0 ] && continue

                    read -r rtt loss jitter throughput syn_time <<< "$result"
                    score=$(echo "scale=4; ($throughput * 1000) / (($rtt + $jitter) * (1 + $loss/100) * $syn_time)" | bc)

                    echo -e "${GREEN}Score: $score${NC}"
                    if (( $(echo "$score > $best_score" | bc -l) )); then
                        best_score=$score
                        best_combo="$dest $cc $qdisc $tc $rtt $loss $jitter $throughput $syn_time"
                    fi
                done
            done
        done
    done

    echo -e "${GREEN}Best combination: $best_combo${NC}"
    echo -e "${GREEN}Best score: $best_score${NC}"
    echo "$best_combo"
}
