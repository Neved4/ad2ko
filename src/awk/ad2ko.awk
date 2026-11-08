#!/usr/bin/awk -f

BEGIN {
	split("Printuno Sometro Awtempo Vinro", month_names)
	special_day_names[2] = "Terakoro Day"
	special_day_names[4] = "Korilo Day"
	iso_fmt = 0; had_error = 0; have_date = 0
	gregorian["year"] = 0
	parse_options()
}

function leap(year) {
	return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

function day_of_year(year, month, day, idx) {
	for (idx = 1; idx < month; idx++) {
		if (idx == 2) {
			day += leap(year) ? 29 : 28
		} else if (idx == 4 || idx == 6 ||
			idx == 9 || idx == 11) {
			day += 30
		} else {
			day += 31
		}
	}
	return day
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
	split(value, fields, "-")
	year = fields[1] + 0
	month = fields[2] + 0
	day = fields[3] + 0
	if (year < 1 || month < 1 || month > 12) {
		return 0
	}
	return day >= 1 && day <= days_in_month(year, month)
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

function parse_options(idx) {
	for (idx = 1; idx < ARGC; idx++) {
		if (ARGV[idx] == "-i") {
			iso_fmt = 1
			delete ARGV[idx]
		} else if (ARGV[idx] == "-h" || \
			ARGV[idx] == "--help") {
			usage()
			skip_end = 1
			exit 0
		} else if (ARGV[idx] ~ /^-/) {
			errmsg("invalid option: " ARGV[idx])
			usage()
			skip_end = 1
			exit 2
		}
	}
}

function usage() {
	print "Usage: ad2ko.awk [-i] [date-file ...]" > "/dev/stderr"
	print "Convert YYYY-MM-DD input dates to Korilo dates." > "/dev/stderr"
	print "  -i       Print output in ISO 8601 format" > "/dev/stderr"
	print "  -h       Show this help" > "/dev/stderr"
}

function errmsg(message) {
	print "Error: " message > "/dev/stderr"
}

function print_date(date, iso, month, day, name) {
	month = date["month"]
	day = date["day"]
	if (iso) {
		printf "%04d-%02d-%02d\n", date["year"], month, day
	} else if (day == 91 && month in special_day_names) {
		printf "%s, %d\n", special_day_names[month], date["year"]
	} else {
		printf "%s %02d, %d\n", month_names[month], day, date["year"]
	}
}

{
	read_date(gregorian, $0, 1)
}

END {
	if (!skip_end && !NR) {
		read_current_date(gregorian)
	}
	if (had_error) {
		exit 1
	}
}
