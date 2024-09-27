CC=gcc
CFLAGS=-Wall -Wextra -O2
SRC_DIR=src

all: $(SRC_DIR)/tcp_connect_time $(SRC_DIR)/optimize_tcp_params

$(SRC_DIR)/tcp_connect_time: $(SRC_DIR)/tcp_connect_time.c
	$(CC) $(CFLAGS) -o $@ $<

$(SRC_DIR)/optimize_tcp_params: $(SRC_DIR)/optimize_tcp_params.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f $(SRC_DIR)/tcp_connect_time $(SRC_DIR)/optimize_tcp_params

.PHONY: all clean
