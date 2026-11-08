#ifndef AD2KO_DATE_H
#define AD2KO_DATE_H

#include <stdio.h>
#include <string.h>

static size_t ad2ko_trim_eol(char *line) {
	size_t length;

	length = strlen(line);

	while (length && (line[length - 1] == '\n' ||
		line[length - 1] == '\r')) {
		line[--length] = '\0';
	}
	return length;
}

static int ad2ko_days_in_month(int year, int month) {
	static const int days[] = {
		31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
	};

	if (month == 2 && !(year % 4) && (year % 100 || !(year % 400))) {
		return 29;
	}
	return days[month - 1];
}

static int ad2ko_valid_date(int year, int month, int day) {
	return year > 0 && month > 0 && month <= 12 && day > 0 &&
		day <= ad2ko_days_in_month(year, month);
}

static void ad2ko_convert_date(const char *year_text,
	const char *month_text, const char *day_text,
	int *year, int *month, int *day) {
	*year = (year_text[0] - '0') * 1000 +
		(year_text[1] - '0') * 100 + (year_text[2] - '0') * 10 +
		year_text[3] - '0';
	*month = (month_text[0] - '0') * 10 + month_text[1] - '0';
	*day = (day_text[0] - '0') * 10 + day_text[1] - '0';
}

static int ad2ko_parse_date_line(const char *line, int *year,
	int *month, int *day) {
	char y[5], m[3], d[3];
	int used;

	used = 0;

	if (sscanf(line, "%4[0-9]-%2[0-9]-%2[0-9]%n",
		y, m, d, &used) != 3) {
		return 0;
	}
	if (used != 10 || strspn(line + used, "\r\n") !=
		strlen(line + used)) {
		return 0;
	}
	ad2ko_convert_date(y, m, d, year, month, day);
	return ad2ko_valid_date(*year, *month, *day);
}

static int ad2ko_read_date_line(FILE *stream, char *line, size_t size) {
	int ch;

	if (!fgets(line, (int)size, stream)) {
		return 0;
	}
	if (strchr(line, '\n')) {
		return 1;
	}
	ch = fgetc(stream);
	if (ch == EOF) {
		return 1;
	}
	while (ch != '\n' && ch != EOF) {
		ch = fgetc(stream);
	}
	return -1;
}

static int ad2ko_scan_date(FILE *stream, int *year, int *month, int *day) {
	char line[16];

	if (ad2ko_read_date_line(stream, line, sizeof(line)) != 1) {
		return 0;
	}
	return ad2ko_parse_date_line(line, year, month, day);
}

#endif
