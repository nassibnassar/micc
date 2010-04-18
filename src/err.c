#include <stdlib.h>
#include <stdio.h>

char *prgname;

void generr(char *msg)
{
	fprintf(stderr, "%s: %s\n", prgname, msg);
}

void fileerr(char *fn, char *msg)
{
	fprintf(stderr, "%s: %s: %s\n", prgname, fn, msg);
}

