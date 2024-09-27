#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/time.h>
#include <netdb.h>

#define MAX_ATTEMPTS 3
#define TIMEOUT_SEC 5

double measure_connect_time(const char *host, int port) {
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
    
    double total_time = 0;
    int successful_attempts = 0;
    
    for (int i = 0; i < MAX_ATTEMPTS; i++) {
        double connect_time = measure_connect_time(host, port);
        if (connect_time >= 0) {
            total_time += connect_time;
            successful_attempts++;
        }
        usleep(100000);  // 100ms delay between attempts
    }
    
    if (successful_attempts > 0) {
        double average_time = total_time / successful_attempts;
        printf("%.6f\n", average_time);
        return 0;
    } else {
        fprintf(stderr, "All connection attempts failed\n");
        return 1;
    }
}
