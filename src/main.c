/*
 *  Copyright (C) 2005  Etymon Systems, Inc.
 *
 *  Authors:  Nassib Nassar
 */

#include <stdlib.h>
#include <sys/stat.h>
#include "opt.h"
#include "err.h"
#include "help.h"
#include "process.h"

static int exists(const char *fn)
{
	struct stat st;
	
	return !stat(fn, &st);
}

static void assertinputs(Opt *opt)
{
	int x;
	int found = 0;
	int missing = 0;
	char **nargv = opt->nargv;
	int nargc = opt->nargc;
	char *ifn;
	
	if (nargv) {
		for (x = 0; x < nargc; x++) {
			ifn = nargv[x];
			if (exists(ifn)) {
				found = 1;
			} else {
				fileerr(ifn, "No such file or directory");
				missing = 1;
			}
		}
	}
	if (!found) {
		generr("no input files");
		exit(1);
	}
	if (missing)
		exit(1);
}

static void dispatch(Opt *opt)
{
	if (opt->help)
		help();

	assertinputs(opt);
	processall(opt);
}

int main(int argc, char *argv[])
{
	Opt opt;

	prgname = argv[0];
	evalopt(argc, argv, &opt);
	dispatch(&opt);
	return 0;
}
