.POSIX:
.PHONY: all build ad2ko

CC ?= cc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
BUILD_DIR ?= build

TARGETS := ${BUILD_DIR}/ad2ko

all: ${TARGETS}

build: all

ad2ko: ${BUILD_DIR}/ad2ko

${BUILD_DIR}/ad2ko: src/c/main.c src/c/date.h
	mkdir -p "${BUILD_DIR}"
	${CC} ${CFLAGS} -o "$@" "$<"
