# Compiler settings
CC := gcc
CFLAGS := -Wall -Wextra -O2

# Directories
SRC_DIR := src
BIN_DIR := $(SRC_DIR)

# Source files and targets
SOURCES := $(wildcard $(SRC_DIR)/*.c)
TARGETS := $(patsubst $(SRC_DIR)/%.c,$(BIN_DIR)/%,$(SOURCES))

# Phony targets
.PHONY: all clean

# Default target
all: $(TARGETS)

# Compile rule
$(BIN_DIR)/%: $(SRC_DIR)/%.c
	@mkdir -p $(BIN_DIR)
	$(CC) $(CFLAGS) $< -o $@

# Clean rule
clean:
	rm -f $(TARGETS)

# Print variables for debugging
print-%:
	@echo '$*=$($*)'
