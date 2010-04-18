#ifndef _SYMTABLE_H
#define _SYMTABLE_H

#include "common.h"

typedef struct {
	char name[1024];
	int var;  /* 0 = function, 1 = variable */
	int type;  /* 0 = void, 1 = int */
	int isnew;
} Symbol;

extern Symbol symt[1024];
extern int symtn;

char parsefile[MAXPATHSIZE];

#endif
