CC=gcc
CFLAGS=-Wall -Wextra -O2
SRC_DIR=src
BIN_DIR=bin

all: $(BIN_DIR)/tcp_connect_time $(BIN_DIR)/optimize_tcp_params

$(BIN_DIR)/tcp_connect_time: $(SRC_DIR)/tcp_connect_time.c
	@mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $<

$(BIN_DIR)/optimize_tcp_params: $(SRC_DIR)/optimize_tcp_params.c
	@mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -rf $(BIN_DIR)

.PHONY: all clean
