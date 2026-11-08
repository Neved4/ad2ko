#!/bin/sh
set -efu

cd "$(dirname "$0")/.."
make build
hyperfine -N -w 4 -r 8 \
	-n C './build/ad2ko -f tools/dates.txt' \
	-n Awk 'awk -f src/awk/ad2ko.awk tools/dates.txt' \
	-n Python './src/py/ad2ko.py -f tools/dates.txt'
date_file=$(mktemp)
trap 'rm -f "$date_file"' EXIT HUP INT TERM
printf '2024-03-20\n' > "$date_file"
hyperfine -N -w 4 -r 8 \
	-n C "./build/ad2ko -f $date_file" \
	-n Awk "awk -f src/awk/ad2ko.awk $date_file" \
	-n Python "./src/py/ad2ko.py -f $date_file"
