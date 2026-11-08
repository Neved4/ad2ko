#!/bin/sh
set -efu

cd "$(dirname "$0")/.."
make build
hyperfine -N -w 4 -r 8 \
	-n C './build/ad2ko -f tools/dates.txt' \
	-n Awk 'awk -f src/awk/ad2ko.awk tools/dates.txt' \
	-n Python './src/py/ad2ko.py -f tools/dates.txt'
hyperfine -N -w 4 -r 8 \
	-n C "printf '2024-03-20\n' | ./build/ad2ko" \
	-n Awk "printf '2024-03-20\n' | awk -f src/awk/ad2ko.awk" \
	-n Python "printf '2024-03-20\n' | ./src/py/ad2ko.py"
