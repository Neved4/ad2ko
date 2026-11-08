#!/usr/bin/awk -f

BEGIN {
	split("Printuno Sometro Awtempo Vinro", month_names)
	special_day_names[2] = "Terakoro Day"
	special_day_names[4] = "Korilo Day"
	iso_fmt = 0
	had_error = 0
	have_date = 0
	gregorian["year"] = 0
	parse_options()
}

function leap(year) {
	return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
}

function day_of_year(year, month, day, i) {
	for (i = 1; i < month; i++) {
		if (i == 2) {
			day += leap(year) ? 29 : 28
		} else if (i == 4 || i == 6 ||
			i == 9 || i == 11) {
			day += 30
		} else {
			day += 31
		}
	}
	return day
}

function cycle_date(year, doy, map, i) {
	i = (286 + doy - 1) % 365
	if (leap(year) && doy == 262) {
		map["month"] = 2
		map["day"] = 91
		return
	}
	if (leap(year) && doy > 262) {
		i = (i - 1) % 365
	}
	map["month"] = i == 364 \
		? 4 : int(i / 91) + 1
	map["day"] = i == 364 ? 91 : i % 91
}

function map_date(gregorian, map, doy, boundary) {
	doy = day_of_year(gregorian["year"], gregorian["month"],
		gregorian["day"])
	cycle_date(gregorian["year"], doy, map)
	boundary = leap(gregorian["year"]) ? 20 : 21
	if (gregorian["month"] < 3 ||
		(gregorian["month"] == 3 && gregorian["day"] < boundary)) {
		map["year"] = gregorian["year"] - 2025
	} else {
		map["year"] = gregorian["year"] - 2024
	}
}

function current_date(date, cmd, value, fields) {
	cmd = "date -u +'%Y-%m-%d'"
	cmd | getline value
	close(cmd)
	split(value, fields, "-")
	date["year"] = fields[1] + 0
	date["month"] = fields[2] + 0
	date["day"] = fields[3] + 0
}

function read_date(date, value, from_input, fields) {
	if (from_input) {
		process_input_date(date, value)
		return
	}
	read_current_date(date)
}

function process_input_date(date, value, fields, map) {
	sub(/\r$/, "", value)
	if (!valid_date(value, fields)) {
		errmsg("invalid date format: " value)
		had_error = 1
		return
	}
	date["year"] = fields[1] + 0
	date["month"] = fields[2] + 0
	date["day"] = fields[3] + 0
	map_date(date, map)
	print_date(map, iso_fmt)
	have_date = 1
}

function read_current_date(date, map) {
	if (have_date) {
		return
	}
	if (system("[ -t 0 ]") != 0) {
		errmsg("invalid date format")
		exit 1
	}
	current_date(date)
	map_date(date, map)
	print_date(map, iso_fmt)
}

function valid_date(value, fields, year, month, day) {
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

function parse_options(i) {
	for (i = 1; i < ARGC; i++) {
		if (ARGV[i] == "-i") {
			iso_fmt = 1
			ARGV[i] = ""
		} else if (ARGV[i] == "-h" || \
			ARGV[i] == "--help") {
			usage()
			skip_end = 1
			exit 0
		} else if (ARGV[i] ~ /^-/) {
			errmsg("invalid option: " ARGV[i])
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

function print_date(date, iso, month, day) {
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
