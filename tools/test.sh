#!/bin/sh
set -Cefu

script_dir="${0%/*}"
dates_path=$script_dir/dates.txt
  exe_path=$script_dir/../ad2mo

while IFS= read -r line
do
	$exe_path "$line"
done < "$dates_path"
