#!/bin/sh
set -Cefu

script_dir="${0%/*}"
dates_path=$script_dir/dates.txt
exe_path=$script_dir/../build/ad2ko

"$exe_path" -f "$dates_path" > /dev/null
