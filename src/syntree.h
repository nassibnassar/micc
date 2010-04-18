#ifndef _SYNTREE_H
#define _SYNTREE_H

#define  TYPECON  0
#define  TYPEID   1
#define  TYPEOP   2

typedef struct {
	int con;  /* constant value */
} Synconst;

typedef struct {
	int id;  /* index in symbol table */
} Synid;

typedef struct {
	int op;
	int opn;
	struct SyntreeTag *opa[3];
} Synop;

typedef struct SyntreeTag {
	int type;  /* TYPECON, TYPEID, or TYPEOP */
	union {
		Synconst con;
		Synid id;
		Synop op;
	} u;
} Syntree;

extern Syntree *tree;

Syntree *makecon(int value);
Syntree *makeid(int id);
Syntree *makeop(int oper, int opn, Syntree *opa0, Syntree *opa1, Syntree *opa2);
void dumptree(Syntree *p);

#endif
