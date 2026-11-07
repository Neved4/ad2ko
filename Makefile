CC ?= cc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
BUILD_DIR ?= build

PROGRAMS := ad2mo ad2mo_fgets ad2mo_fstat ad2mo_getline
SOURCES := $(addsuffix .c,$(PROGRAMS))
TARGETS := $(addprefix $(BUILD_DIR)/,$(PROGRAMS))

.PHONY: all ad2mo

all: $(TARGETS)

ad2mo: $(BUILD_DIR)/ad2mo

$(BUILD_DIR):
	mkdir -p "$@"

$(BUILD_DIR)/%: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -o "$@" "$<"

