/*
 *  Copyright (C) 2005  Etymon Systems, Inc.
 *
 *  Authors:  Nassib Nassar
 */

#include <stdio.h>
#include <string.h>
#include "symtable.h"

extern FILE *yyout;

Symbol symt[1024];
int symtn = 0;

/* locate symbol or add it to table */
int symadd(char *sym)
{
	int x;

	for (x = 0; x < symtn; x++) {
		if (!strcmp(symt[x].name, sym)) {
			symt[x].isnew = 0;
			return x;
		}
	}
	strcpy(symt[symtn].name, sym);
	symt[symtn].var = 0;
	symt[symtn].type = 0;
	symt[symtn].isnew = 1;
	return symtn++;
}

int symaddstr(char *sym)
{
	char s[1024];
	char *x = sym;
	char *y = s;
	int quoting = 0;
	while (*x) {
		if (!quoting) {
			if (*(x++) == '"')
				quoting = 1;
			continue;
		}
		switch (*x) {
		case '"':
			quoting = 0;
			break;
		case '\\':
			switch (*(++x)) {
			case 'n':
				*(y++) = '\n';
				break;
			case 't':
				*(y++) = '\t';
				break;
			default:
				*(y++) = *x;
			}
			break;
		default:
			*(y++) = *x;
		}
		x++;
	}
	*y = '\0';
	return symadd(s);
}

void dumpsymt()
{
	int x;

	fprintf(yyout, "\n;  Symbol table\n");
	for (x = 0; x < symtn; x++) {
		fprintf(yyout, ";  (%d) \"%s\"\tV=%i\n", x, symt[x].name, symt[x].var);
	}
}


