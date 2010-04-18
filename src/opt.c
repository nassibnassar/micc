/*
 *  Copyright (C) 2005  Etymon Systems, Inc.
 *
 *  Authors:  Nassib Nassar
 */

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <getopt.h>
#include "opt.h"
#include "err.h"

void initopt(Opt *opt)
{
	memset(opt, 0, sizeof (Opt));
}

static void evaloptlong(char *name, char *arg, Opt *opt)
{
	if (!strcmp(name, "help")) {
		opt->help = 1;
		return;
	}
}

static void optionerr(char *msg, int g, char *optarg)
{
	fprintf(stderr, "%s: %s `-%c%s'\n", prgname, msg, g, optarg);
}

void evalopt(int argc, char *argv[], Opt *opt)
{
	static struct option longopts[] = {
		{ "help", 0, 0, 0 },
		{ 0, 0, 0, 0 }
	};
	int g;

	initopt(opt);
	while (1) {
		int longindex = 0;
		g = getopt_long(argc, argv,
				"EScf:o:s:",
				longopts, &longindex);
		if (g == -1)
			break;
		switch (g) {
		case 0:
			evaloptlong(
				(char *)longopts[longindex].name,
				optarg, opt);
			break;
		case 'E':
			opt->E = 1;
			break;
		case 'c':
			opt->c = 1;
			break;
		case 'o':
			opt->o = optarg;
			break;
		case 's':
			if (!strcmp(optarg, "ave-temps")) {
				opt->save_temps = 1;
				break;
			}
			optionerr("unrecognized option", g, optarg);
			break;
		case 'f':
/*			if (!strcmp(optarg, "dump-options")) {
				opt->dump_options = 1;
				break;
				} */
			break;
		case '?':
			return /*-1*/;
			/*default:
			printf("getopt error: %o\n", g);*/
		}
	}
	if (optind < argc) {
		opt->nargv = argv + optind;
		opt->nargc = argc - optind;
	}
}
