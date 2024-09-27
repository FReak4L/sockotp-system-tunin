#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/time.h>

#define MAX_ATTEMPTS 5
#define TIMEOUT_SEC 5

double measure_tcp_performance(const char *host, int port, int window_size, int mss) {
    struct addrinfo hints, *res, *res0;
    int sockfd;
    struct timeval start, end, timeout;
    double elapsed = -1;

    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;

    char port_str[6];
    snprintf(port_str, sizeof(port_str), "%d", port);

    int err = getaddrinfo(host, port_str, &hints, &res0);
    if (err != 0) {
        fprintf(stderr, "getaddrinfo error: %s\n", gai_strerror(err));
        return -1;
    }

    for (res = res0; res; res = res->ai_next) {
        sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
        if (sockfd < 0) continue;

        // Set window size
        if (setsockopt(sockfd, SOL_SOCKET, SO_RCVBUF, &window_size, sizeof(window_size)) < 0) {
            perror("setsockopt SO_RCVBUF");
            close(sockfd);
            continue;
        }
        if (setsockopt(sockfd, SOL_SOCKET, SO_SNDBUF, &window_size, sizeof(window_size)) < 0) {
            perror("setsockopt SO_SNDBUF");
            close(sockfd);
            continue;
        }

        // Set MSS
        if (setsockopt(sockfd, IPPROTO_TCP, TCP_MAXSEG, &mss, sizeof(mss)) < 0) {
            perror("setsockopt TCP_MAXSEG");
            close(sockfd);
            continue;
        }

        int flags = fcntl(sockfd, F_GETFL, 0);
        fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);

        gettimeofday(&start, NULL);
        
        if (connect(sockfd, res->ai_addr, res->ai_addrlen) < 0) {
            if (errno == EINPROGRESS) {
                fd_set fdset;
                FD_ZERO(&fdset);
                FD_SET(sockfd, &fdset);
                timeout.tv_sec = TIMEOUT_SEC;
                timeout.tv_usec = 0;

                int rc = select(sockfd + 1, NULL, &fdset, NULL, &timeout);
                if (rc > 0) {
                    int error;
                    socklen_t len = sizeof(error);
                    if (getsockopt(sockfd, SOL_SOCKET, SO_ERROR, &error, &len) == 0 && error == 0) {
                        gettimeofday(&end, NULL);
                        elapsed = (end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1e6;
                        close(sockfd);
                        break;
                    }
                }
            }
        } else {
            gettimeofday(&end, NULL);
            elapsed = (end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec) / 1e6;
            close(sockfd);
            break;
        }

        close(sockfd);
    }

    freeaddrinfo(res0);
    return elapsed;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <host> <port>\n", argv[0]);
        exit(1);
    }

    const char *host = argv[1];
    int port = atoi(argv[2]);
    
    int window_sizes[] = {65536, 131072, 262144, 524288, 1048576};
    int mss_values[] = {536, 1460, 9000};
    
    double best_time = -1;
    int best_window_size = 0;
    int best_mss = 0;

    for (int i = 0; i < sizeof(window_sizes) / sizeof(window_sizes[0]); i++) {
        for (int j = 0; j < sizeof(mss_values) / sizeof(mss_values[0]); j++) {
            double total_time = 0;
            int successful_attempts = 0;

            for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
                double connect_time = measure_tcp_performance(host, port, window_sizes[i], mss_values[j]);
                if (connect_time >= 0) {
                    total_time += connect_time;
                    successful_attempts++;
                }
                usleep(100000);  // 100ms delay between attempts
            }

            if (successful_attempts > 0) {
                double average_time = total_time / successful_attempts;
                printf("Window Size: %d, MSS: %d, Average Time: %.6f\n", window_sizes[i], mss_values[j], average_time);

                if (best_time < 0 || average_time < best_time) {
                    best_time = average_time;
                    best_window_size = window_sizes[i];
                    best_mss = mss_values[j];
                }
            }
        }
    }

    if (best_time >= 0) {
        printf("Best configuration - Window Size: %d, MSS: %d, Time: %.6f\n", best_window_size, best_mss, best_time);
        return 0;
    } else {
        fprintf(stderr, "All connection attempts failed\n");
        return 1;
    }
}
