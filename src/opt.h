#ifndef _OPT_H
#define _OPT_H

typedef struct {
	int E;
	int c;
	char *o;
	char *s;
	int save_temps;
	int help;
	int nargc;
	char **nargv;
} Opt;

void evalopt(int argc, char *argv[], Opt *opt);
void dumpopt(Opt *opt);

#endif
