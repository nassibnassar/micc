/*
 *  Copyright (C) 2005  Etymon Systems, Inc.
 *
 *  Authors:  Nassib Nassar
 */

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include "syntree.h"
#include "symtable.h"
#include "y.tab.h"

extern FILE *yyout;

Syntree *tree;

Syntree *makecon(int value)
{
	Syntree *p;

	p = (Syntree *) malloc(sizeof (Syntree));
	p->type = 0;
	p->u.con.con = value;
	return p;
}

Syntree *makeid(int id)
{
	Syntree *p;

	p = (Syntree *) malloc(sizeof (Syntree));
	p->type = 1;
	p->u.id.id = id;
	return p;
}

Syntree *makeop(int oper, int opn, Syntree *opa0, Syntree *opa1, Syntree *opa2)
{
	Syntree *p;

	p = (Syntree *) malloc(sizeof (Syntree));
	p->type = 2;
	p->u.op.op = oper;
	p->u.op.opn = opn;
	p->u.op.opa[0] = opa0;
	p->u.op.opa[1] = opa1;
	p->u.op.opa[2] = opa2;
	return p;
}

static void indent(int ind)
{
	int x;
	fprintf(yyout, ";  ");
	for (x = 0; x < ind; x++) {
		fprintf(yyout, " ");
	}
}

static void dumpsubtree(Syntree *p, int ind)
{
	int x;
	if (!p) {
		indent(ind);
		fprintf(yyout, "(NULL)\n");
		return;
	}

	fflush(yyout);
	switch (p->type) {
	case 0:
		indent(ind);
		fprintf(yyout, "(C) \"%i\"\n", p->u.con.con);
		break;
	case 1:
		indent(ind);
		fprintf(yyout, "(I) \"%s\"\n", symt[p->u.id.id].name);
		break;
	case 2:
		indent(ind);
		fprintf(yyout, "(O) ");
		switch (p->u.op.op) {
		case RETURN:
			fprintf(yyout, "RETURN");
			break;
		default:
			if (isprint(p->u.op.op))
				fprintf(yyout, "'%c'", p->u.op.op);
			else
				fprintf(yyout, "%i", p->u.op.op);
		}
		fprintf(yyout, " [%i] {\n", p->u.op.opn);
		for (x = 0; x < p->u.op.opn; x++) {
			dumpsubtree(p->u.op.opa[x], ind + 4);
		}
		indent(ind);
		fprintf(yyout, "}\n");
	}
}

void dumptree(Syntree *p)
{
/*	fprintf(yyout, "\n;  Syntax tree\n"); */
	dumpsubtree(p, 0);
}
