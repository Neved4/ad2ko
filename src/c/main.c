#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#ifdef _WIN32
	#include <io.h>
	#define stdin_is_tty() _isatty(_fileno(stdin))
#else
	#include <unistd.h>
	#define stdin_is_tty() isatty(STDIN_FILENO)
#endif
#include "date.h"

struct date {
	int year, month, day;
};

static const char *month_names[] = {
	"Printuno", "Sometro", "Awtempo", "Vinro"
};

static void errmsg(const char *message);

static int leap(int year) {
	return (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
}

static int day_of_year(struct date date) {
	static const int days[] = {
		31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
	};
	int day, index;

	day = date.day;
	for (index = 1; index < date.month; index++) {
		day += index == 2 && leap(date.year) ? 29 : days[index - 1];
	}
	return day;
}

static struct date cycle_date(int year, int doy) {
	struct date date;
	int index;

	index = (286 + doy - 1) % 365;
	if (leap(year) && doy == 262) {
		return (struct date){year, 2, 91};
	}

	if (leap(year) && doy > 262) {
		index = (index + 364) % 365;
	}

	date.month = index == 364 ? 4 : index / 91 + 1;
	date.day = index == 364 ? 91 : index % 91;
	return date;
}

static struct date map_date(struct date gregorian) {
	struct date date;
	int doy, boundary, prior_year;

	doy = day_of_year(gregorian);
	boundary = leap(gregorian.year) ? 20 : 21;
	prior_year = gregorian.month < 3 ||
		(gregorian.month == 3 && gregorian.day < boundary);
	date = cycle_date(gregorian.year, doy);
	date.year = gregorian.year - (prior_year ? 2025 : 2024);
	return date;
}

static void current_date(struct date *date) {
	time_t now = time(NULL);
	struct tm *utc = gmtime(&now);
	date->year = utc->tm_year + 1900;
	date->month = utc->tm_mon + 1;
	date->day = utc->tm_mday;
}

static int read_date(struct date *date) {
	if (stdin_is_tty()) {
		current_date(date);
		return 1;
	}

	return ad2ko_scan_date(stdin, &date->year, &date->month, &date->day);
}

static void print_date(struct date date, int iso) {
	const char *name;

	if (iso) {
		printf("%04d-%02d-%02d\n", date.year, date.month, date.day);
	} else if (date.day == 91 && (date.month == 2 || date.month == 4)) {
		name = date.month == 2 ? "Terakoro" : "Korilo";
		printf("%s Day, %d\n", name, date.year);
	} else if (date.month >= 1 && date.month <= 4) {
		printf("%s %d, %d\n", month_names[date.month - 1], date.day, date.year);
	} else {
		errmsg("invalid date mapping");
	}
}

static void usage(void) {
	fprintf(stderr, "%s",
		"usage: ad2ko [-i] [-f file]\n"
		"  -i       Print ISO 8601 output\n"
		"  -f file  Read dates from file\n");
}

static void errmsg(const char *message) {
	fprintf(stderr, "error: %s\n", message);
}

static int parse_options(int argc, char **argv, int *iso, const char **file) {
	int i;

	for (i = 1; i < argc; i++) {
		if (!strcmp(argv[i], "-i")) {
			*iso = 1;
		} else if (!strcmp(argv[i], "-f") && i + 1 < argc) {
			*file = argv[++i];
		} else {
			return 0;
		}
	}

	return 1;
}

static void process_line(char *line, int iso, int *had_error) {
	struct date date;

	ad2ko_trim_eol(line);
	if (ad2ko_parse_date_line(line, &date.year, &date.month, &date.day)) {
		print_date(map_date(date), iso);
		return;
	}

	fprintf(stderr, "Error: invalid date format: %s\n", line);
	*had_error = 1;
}

static int read_file(FILE *file, int iso) {
	char line[16];
	int status, had_error;

	had_error = 0;
	while ((status = ad2ko_read_date_line(file, line, sizeof(line)))) {
		if (status < 0) {
		errmsg("invalid date format: line too long");
			had_error = 1;
			continue;
		}
		process_line(line, iso, &had_error);
	}

	return had_error || ferror(file) ? 1 : 0;
}

static int process_file(const char *path, int iso) {
	FILE *file;
	int result;

	file = fopen(path, "r");
	if (!file) {
		fprintf(stderr, "Error: %s: %s\n", path, strerror(errno));
		return 1;
	}

	result = read_file(file, iso);
	if (fclose(file)) {
		fprintf(stderr, "Error: %s: %s\n", path, strerror(errno));
		result = 1;
	}

	return result;
}

int main(int argc, char **argv) {
	int iso;
	const char *file;
	struct date date;

	iso = 0, file = NULL;

	if (!parse_options(argc, argv, &iso, &file)) {
		errmsg("invalid option");
		usage();
		return 1;
	}

	if (file) {
		return process_file(file, iso);
	}

	if (!read_date(&date)) {
		errmsg("invalid date format");
		return 1;
	}

	print_date(map_date(date), iso);
	return 0;
}
