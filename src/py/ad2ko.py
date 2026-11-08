#!/usr/bin/env python3
"""Convert Gregorian dates to Korilo dates."""

import argparse
from datetime import date, datetime, timezone
import re
import sys

MONTHS = ("Printuno", "Sometro", "Awtempo", "Vinro")

def is_leap(year):
	return year % 4 == 0 and (year % 100 != 0 or year % 400 == 0)

def parse_date(value):
	if not re.fullmatch(r"[0-9]{4}-[0-9]{2}-[0-9]{2}", value):
		raise ValueError(f"invalid date format: {value}")
	try:
		return date.fromisoformat(value)
	except ValueError as error:
		raise ValueError(f"invalid date format: {value}") from error

def cycle_date(year, day):
	index = (285 + day - int(is_leap(year) and day > 262)) % 365
	if is_leap(year) and day == 262:
		return 2, 91
	return (4, 91) if index == 364 else (index // 91 + 1, index % 91)

def map_date(gregorian):
	year, day = gregorian.year, gregorian.timetuple().tm_yday
	month, day = cycle_date(year, day)
	prior_year = gregorian.month < 3 or (
		gregorian.month == 3 and gregorian.day < 21 - is_leap(year)
	)
	return year - 2024 - prior_year, month, day

def format_date(mapped, iso):
	year, month, day = mapped
	if iso:
		return f"{year:04d}-{month:02d}-{day:02d}"
	if day == 91 and month in (2, 4):
		return f"{'Terakoro' if month == 2 else 'Korilo'} Day, {year}"
	return f"{MONTHS[month - 1]} {day}, {year}"

def arguments():
	parser = argparse.ArgumentParser(description=__doc__)
	parser.add_argument("-i", action="store_true", help="print ISO 8601 output")
	parser.add_argument("-f", metavar="FILE", help="read dates from file")
	return parser.parse_args()

def current_date():
	return datetime.now(timezone.utc).date()

def input_lines(path):
	if path:
		with open(path, encoding="ascii") as source:
			yield from source
	elif sys.stdin.isatty():
		yield current_date().isoformat()
	else:
		yield from sys.stdin

def convert_lines(lines, iso):
	for line in lines:
		value = line.rstrip("\r\n")
		try:
			yield format_date(map_date(parse_date(value)), iso)
		except ValueError as error:
			print(error, file=sys.stderr)
			yield None

def main():
	options = arguments()
	output = convert_lines(input_lines(options.f), options.i)
	return 1 if any_error(output) else 0

def any_error(lines):
	failed = False
	for line in lines:
		if line is None:
			failed = True
		else:
			print(line)
	return failed

if __name__ == "__main__":
	sys.exit(main())
