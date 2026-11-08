#!/usr/bin/awk -f

function leap(year) {
	return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

function day_of_year(year, month, day, leap_year) {
	leap_year = leap(year)

	return int(275 * month / 9) - int((month + 9) / 12) * \
		(2 - leap_year) + day - 30
}

function cycle_date(year, doy, idx, leap_year) {
	leap_year = leap(year)
	idx = (285 + doy - (leap_year && doy > 262)) % 365

	if (leap_year && doy == 262) {
		mapped_month = 2
		mapped_day = 91
	} else if (idx == 364) {
		mapped_month = 4
		mapped_day = 91
	} else {
		mapped_month = int(idx / 91) + 1
		mapped_day = idx % 91
	}
}

function map_date(year, month, day, prior_year) {
	cycle_date(year, day_of_year(year, month, day))
	prior_year = month < 3 || (month == 3 && day < 21 - leap(year))
	mapped_year = year - 2024 - prior_year
}

function current_date(cmd, value) {
	cmd = "date -u +'%Y-%m-%d'"
	cmd | getline value
	close(cmd)
	process_input_date(value)
}

function read_date(value, from_input) {
	if (from_input) {
		process_input_date(value)
	} else {
		read_current_date()
	}
}

function process_input_date(value) {
	sub(/\r$/, "", value)

	if (!valid_date(value)) {
		err_msg("invalid date format: " value)
		had_err = 1
		return
	}

	map_date(input_year, input_month, input_day)
	print_date(mapped_year, mapped_month, mapped_day, iso_fmt)
	have_date = 1
}

function read_current_date() {
	if (have_date) {
		return
	}

	if (system("[ -t 0 ]") != 0) {
		err_msg("invalid date format")
		had_err = 1
		return
	}

	current_date()
}

function valid_date(value, year, month, day) {
	if (value !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) {
		return 0
	}

	year = substr(value, 1, 4) + 0
	month = substr(value, 6, 2) + 0
	day = substr(value, 9, 2) + 0

	if (year < 1 || month < 1 || month > 12 || day < 1) {
		return 0
	}

	input_year = year
	input_month = month
	input_day = day

	return day <= days_in_month(year, month)
}

function days_in_month(year, month) {
	if (month == 2) {
		return leap(year) ? 29 : 28
	}

	if (month == 4 || month == 6 || month == 9 || month == 11) {
		return 30
	}

	return 31
}

function parse_opts(idx) {
	iso_fmt = iso_fmt + 0
	for (idx = 1; idx < ARGC; idx++) {
		if (ARGV[idx] == "-i") {
			iso_fmt = 1; delete ARGV[idx]
		} else if (ARGV[idx] == "-h" || ARGV[idx] == "--help") {
			usage()
			skip_end = 1; exit 0
		} else if (ARGV[idx] ~ /^-/) {
			err_msg("invalid option: " ARGV[idx])
			usage()
			skip_end = 1; exit 2
		}
	}
}

function usage() {
	print "Usage: ad2ko.awk [-i] [date-file ...]" > "/dev/stderr"
	print "Convert YYYY-MM-DD input dates to Korilo dates." > "/dev/stderr"
	print "  -i       Print output in ISO 8601 format" > "/dev/stderr"
	print "  -h       Show this help" > "/dev/stderr"
}

function err_msg(message) {
	print "Error: " message > "/dev/stderr"
}

function print_date(year, month, day, iso, name) {
	if (iso) {
		printf "%04d-%02d-%02d\n", year, month, day
	} else if (day == 91 && (month == 2 || month == 4)) {
		name = month == 2 ? "Terakoro" : "Korilo"
		printf "%s Day, %d\n", name, year
	} else {
		name = month == 1 ? "Printuno" : month == 2 ? "Sometro" : \
			month == 3 ? "Awtempo" : "Vinro"
		printf "%s %02d, %d\n", name, day, year
	}
}

BEGIN {
	parse_opts()
}

{
	read_date($0, 1)
}

END {
	if (!skip_end && !NR) {
		read_current_date()
	}

	if (had_err) {
		exit 1
	}
}
