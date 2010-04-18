/*
 *  Copyright (C) 2005  Etymon Systems, Inc.
 *
 *  Authors:  Nassib Nassar
 */

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include "common.h"
#include "opt.h"
#include "c.h"
#include "err.h"

static char *getsuffix(char *fn)
{
	char *suffix = strrchr(fn, '.');

	return suffix ? suffix : fn + strlen(fn);
}

static void replacesuffix(char *fn, char *newsuffix)
{
	strcpy(getsuffix(fn), newsuffix);
}

static void preprocess(Opt *opt, char *ifn, char *ofn)
{
	char sys[MAXPATHSIZE * 3];

	if (opt->E) {
		strcpy(ofn, "");
	} else {
		strcpy(ofn, ifn);
		replacesuffix(ofn, ".i");
	}
	sprintf(sys, "sh -c 'cpp -I /usr/local/include/micc -include p16f877a.h %s %s'", ifn, ofn);
	system(sys);
}

static void compile(Opt *opt, char *ifn, char *ofn)
{
	strcpy(ofn, ifn);
	replacesuffix(ofn, ".s");
	yycompile(opt, ifn, ofn);
	if (!opt->save_temps)
		unlink(ifn);
}

void process(Opt *opt, char *ifn)
{
	char *suffix = getsuffix(ifn);
	char cpp[MAXPATHSIZE], s[MAXPATHSIZE], hex[MAXPATHSIZE];

	if (!strcmp(suffix, ".c")) {
		preprocess(opt, ifn, cpp);
		if (opt->E)
			return;
		compile(opt, cpp, s);
		return;
	}
}

#define CATBLOCKSIZE (65536)

static void cat(FILE *ofile, char *ifn)
{
	char block[CATBLOCKSIZE];
	size_t c;
	FILE *ifile = fopen(ifn, "r");

	if (!ifile) {
		fileerr(ifn, "No such file or directory");
		return;
	}
	do {
		c = fread(block, 1, CATBLOCKSIZE, ifile);
		fwrite(block, 1, c, ofile);
	} while (c == CATBLOCKSIZE);
	fclose(ifile);
}

static void linkasm(Opt *opt, char *ofn)
{
	FILE *ofile;
	int x;
	char tmp[MAXPATHSIZE];

	if (opt->o && *(opt->o)) {
		strcpy(ofn, opt->o);
		replacesuffix(ofn, ".asm");
	} else {
		strcpy(ofn, "a.asm");
	}
	ofile = fopen(ofn, "w");
	fprintf(ofile, "list p=16f877a\n");
	fprintf(ofile, "include p16f877a.inc\n\n");
	cat(ofile, "/usr/local/lib/micc/p16f877a.s");
	for (x = 0; x < opt->nargc; x++) {
		strcpy(tmp, opt->nargv[x]);
		replacesuffix(tmp, ".s");
		cat(ofile, tmp);
	}
	fprintf(ofile, "initgvars\n");
	for (x = 0; x < opt->nargc; x++) {
		strcpy(tmp, opt->nargv[x]);
		*getsuffix(tmp) = '\0';
		fprintf(ofile, "\tinit__%s\n", tmp);
	}
	fprintf(ofile, "\treturn\n\n");
	fprintf(ofile, "\tend\n");
	fclose(ofile);
}

static void assemble(Opt *opt)
{
	char asm[MAXPATHSIZE];
	char sys[MAXPATHSIZE * 3];
	char *hex;

	linkasm(opt, asm);
	hex = opt->o && *(opt->o) ? opt->o : "a.hex";
	sprintf(sys, "gpasm -o %s %s | grep -v ':Message \\[302\\] Register in operand not in bank'",
		hex, asm);
	system(sys);
	
	if (!opt->save_temps) {
		unlink(asm);
		replacesuffix(asm, ".cod");
		unlink(asm);
		replacesuffix(asm, ".lst");
		unlink(asm);
	}
}

static void rmintermediate(Opt *opt)
{
	int x;
	char *ifn;
	char *suffix;
	char tmp[MAXPATHSIZE];
	
	for (x = 0; x < opt->nargc; x++) {
		ifn = opt->nargv[x];
		suffix = getsuffix(ifn);
		if (!strcmp(suffix, ".c")) {
			strcpy(tmp, ifn);
			replacesuffix(tmp, ".s");
			if (!opt->save_temps)
				unlink(tmp);
		}
	}
}

void processall(Opt *opt)
{
	int x;
	
	for (x = 0; x < opt->nargc; x++) {
		process(opt, opt->nargv[x]);
	}
	if (!opt->c && !opt->E) {
		assemble(opt);
		rmintermediate(opt);
	}
}
