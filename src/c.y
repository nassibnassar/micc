/* Grammar based on lex/yacc specification developed by Jeff Lee for
    the April 30, 1985 ANSI C draft */

%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include "syntree.h"
#include "symtable.h"
#include "c.h"
	
void docomp(Syntree *p);
int yyparse();
int yylex();
 
extern char yytext[];
extern int column;
extern int line;

int labelcount = 0; 
 
extern FILE *yyin;
extern FILE *yyout;

#define NOS   0; yyerror("unsupported C language construction")
 
char basefn[MAXPATHSIZE];
char srcfn[MAXPATHSIZE];
char cppfn[MAXPATHSIZE];
char asmfn[MAXPATHSIZE];
char lstfn[MAXPATHSIZE];
char codfn[MAXPATHSIZE];
char objfn[MAXPATHSIZE];
int nextgvar = 0;

int yyerror(char *s);

%}

%union {
	int value;
	int sym;
	Syntree *node;
};

%token <sym> IDENTIFIER STRING_LITERAL ASM
%token <value> CONSTANT

%token CONSTANT STRING_LITERAL SIZEOF
%token PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token XOR_ASSIGN OR_ASSIGN TYPE_NAME

%token TYPEDEF EXTERN STATIC AUTO REGISTER
%token CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE CONST VOLATILE VOID
%token STRUCT UNION ENUM ELLIPSIS

%token CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN ASM
%type <node> declarator direct_declarator function_definition argument_expression_list
%type <node> compound_statement statement_list statement expression_statement
%type <node> external_declaration translation_unit source_file declaration
%type <node> declaration_specifiers init_declarator_list init_declarator
%type <node> assignment_expression expression primary_expression
%type <node> postfix_expression unary_expression cast_expression
%type <node> multiplicative_expression additive_expression shift_expression
%type <node> relational_expression equality_expression and_expression
%type <node> exclusive_or_expression inclusive_or_expression logical_and_expression
%type <node> logical_or_expression conditional_expression jump_statement
%type <node> initializer asm_statement iteration_statement selection_statement

%type <value> assignment_operator unary_operator

%start source_file
%%

primary_expression
: IDENTIFIER            { $$ = makeid($1); }
| CONSTANT              { $$ = makecon($1); }
| STRING_LITERAL        { $$ = makeid($1); }
| '(' expression ')'    { $$ = $2; }
;

postfix_expression
: primary_expression					{ $$ = $1; }
| postfix_expression '[' expression ']'			{ $$ = NOS; }
| postfix_expression '(' ')'				{ iddef($1); $$ = makeop('C', 1, $1, NULL, NULL); }
| postfix_expression '(' argument_expression_list ')'	{ iddef($1); $$ = makeop('C', 2, $1, $3, NULL); }
| postfix_expression '.' IDENTIFIER			{ $$ = NOS; }
| postfix_expression PTR_OP IDENTIFIER			{ $$ = NOS; }
| postfix_expression INC_OP				{ $$ = NOS; }
| postfix_expression DEC_OP				{ $$ = NOS; }
;

argument_expression_list
: assignment_expression					{ $$ = $1; }
| argument_expression_list ',' assignment_expression	{ $$ = NOS; }
;

unary_expression
: postfix_expression			{ $$ = $1; }
| INC_OP unary_expression		{ $$ = makeop(INC_OP, 1, $2, NULL, NULL); }
| DEC_OP unary_expression		{ $$ = makeop(DEC_OP, 1, $2, NULL, NULL); }
| unary_operator cast_expression	{ $$ = makeop($1, 1, $2, NULL, NULL); }
| SIZEOF unary_expression		{ $$ = NOS; }
| SIZEOF '(' type_name ')'		{ $$ = NOS; }
;

unary_operator
: '&'             { $$ = NOS; }
| '*'             { $$ = NOS; }
| '+'             { $$ = NOS; }
| '-'             { $$ = '-'; }
| '~'             { $$ = NOS; }
| '!'             { $$ = '!'; }
;

cast_expression
: unary_expression			{ $$ = $1; }
| '(' type_name ')' cast_expression	{ $$ = NOS; }
;

multiplicative_expression
: cast_expression					{ $$ = $1; }
| multiplicative_expression '*' cast_expression		{ $$ = NOS; }
| multiplicative_expression '/' cast_expression		{ $$ = NOS; }
| multiplicative_expression '%' cast_expression		{ $$ = NOS; }
;

additive_expression
: multiplicative_expression				{ $$ = $1; }
| additive_expression '+' multiplicative_expression	{ $$ = makeop('+', 2, $1, $3, NULL); }
| additive_expression '-' multiplicative_expression	{ $$ = makeop('-', 2, $1, $3, NULL); }
;

shift_expression
: additive_expression					{ $$ = $1; }
| shift_expression LEFT_OP additive_expression		{ $$ = makeop(LEFT_OP, 2, $1, $3, NULL); }
| shift_expression RIGHT_OP additive_expression		{ $$ = makeop(RIGHT_OP, 2, $1, $3, NULL); }
;

relational_expression
: shift_expression					{ $$ = $1; }
| relational_expression '<' shift_expression		{ $$ = NOS; }
| relational_expression '>' shift_expression		{ $$ = NOS; }
| relational_expression LE_OP shift_expression		{ $$ = NOS; }
| relational_expression GE_OP shift_expression		{ $$ = NOS; }
;

equality_expression
: relational_expression					{ $$ = $1; }
| equality_expression EQ_OP relational_expression	{ $$ = makeop(EQ_OP, 2, $1, $3, NULL); }
| equality_expression NE_OP relational_expression	{ $$ = NOS; }
;

and_expression
: equality_expression					{ $$ = $1; }
| and_expression '&' equality_expression		{ $$ = makeop('&', 2, $1, $3, NULL); }
;

exclusive_or_expression
: and_expression					{ $$ = $1; }
| exclusive_or_expression '^' and_expression		{ $$ = makeop('^', 2, $1, $3, NULL); }
;

inclusive_or_expression
: exclusive_or_expression				{ $$ = $1; }
| inclusive_or_expression '|' exclusive_or_expression	{ $$ = makeop('|', 2, $1, $3, NULL); }
;

logical_and_expression
: inclusive_or_expression				{ $$ = $1; }
| logical_and_expression AND_OP inclusive_or_expression	{ $$ = makeop(AND_OP, 2, $1, $3, NULL); }
;

logical_or_expression
: logical_and_expression				{ $$ = $1; }
| logical_or_expression OR_OP logical_and_expression	{ $$ = makeop(OR_OP, 2, $1, $3, NULL); }
;

conditional_expression
: logical_or_expression							{ $$ = $1; }
| logical_or_expression '?' expression ':' conditional_expression	{ $$ = NOS; }
;

assignment_expression
: conditional_expression						{ $$ = $1; }
| unary_expression assignment_operator assignment_expression		{ $$ = makeop($2, 2, $1, $3, NULL); }
;

assignment_operator
: '='			{ $$ = '='; }
| MUL_ASSIGN		{ $$ = NOS; }
| DIV_ASSIGN		{ $$ = NOS; }
| MOD_ASSIGN		{ $$ = NOS; }
| ADD_ASSIGN		{ $$ = ADD_ASSIGN; }
| SUB_ASSIGN		{ $$ = SUB_ASSIGN; }
| LEFT_ASSIGN		{ $$ = NOS; }
| RIGHT_ASSIGN		{ $$ = NOS; }
| AND_ASSIGN		{ $$ = NOS; }
| XOR_ASSIGN		{ $$ = NOS; }
| OR_ASSIGN		{ $$ = NOS; }
;

expression
: assignment_expression			{ $$ = $1; }
| expression ',' assignment_expression	{ $$ = makeop(',', 2, $1, $3, NULL); }
;

constant_expression
: conditional_expression
;

declaration
: declaration_specifiers ';'				{ $$ = NOS; }
| declaration_specifiers init_declarator_list ';'	{ $$ = $2; }
;

declaration_specifiers
: storage_class_specifier                             { $$ = NOS; }
| storage_class_specifier declaration_specifiers      { $$ = $2; }
| type_specifier                                      { $$ = makeid(-1); }  /* %%% { fprintf(yyout, "\nDS3\n"); }*/
| type_specifier declaration_specifiers               { $$ = NOS; }
| type_qualifier                                      { $$ = NOS; }
| type_qualifier declaration_specifiers               { $$ = NOS; }
;

init_declarator_list
: init_declarator				{ $$ = $1; }
| init_declarator_list ',' init_declarator	{ $$ = makeop(';', 2, $1, $3, NULL); }
;

init_declarator
: declarator			{ $$ = makeop('D', 1, $1, NULL, NULL); }
| declarator '=' initializer	{ $$ = makeop('D', 2, $1, $3, NULL); }
;

storage_class_specifier
: TYPEDEF  			{ yyerror("type not supported"); }
| EXTERN                        {  }
| STATIC   			{ yyerror("type not supported"); }
| AUTO    			{ yyerror("type not supported"); }
| REGISTER			{ yyerror("type not supported"); }
;

type_specifier
: VOID				{ yyerror("type not supported"); }
| CHAR				{ yyerror("type not supported"); }
| SHORT				{ yyerror("type not supported"); }
| INT				{  }
| LONG				{ yyerror("type not supported"); }
| FLOAT				{ yyerror("type not supported"); }
| DOUBLE			{ yyerror("type not supported"); }
| SIGNED			{ yyerror("type not supported"); }
| UNSIGNED			{ yyerror("type not supported"); }
| struct_or_union_specifier	{ yyerror("type not supported"); }
| enum_specifier		{ yyerror("type not supported"); }
| TYPE_NAME			{ yyerror("type not supported"); }
;

struct_or_union_specifier
	: struct_or_union IDENTIFIER '{' struct_declaration_list '}'
| struct_or_union '{' struct_declaration_list '}'
| struct_or_union IDENTIFIER
;

struct_or_union
	: STRUCT
| UNION
;

struct_declaration_list
	: struct_declaration
| struct_declaration_list struct_declaration
;

struct_declaration
	: specifier_qualifier_list struct_declarator_list ';'
;

specifier_qualifier_list
: type_specifier specifier_qualifier_list
| type_specifier
| type_qualifier specifier_qualifier_list
| type_qualifier
;

struct_declarator_list
	: struct_declarator
| struct_declarator_list ',' struct_declarator
;

struct_declarator
	: declarator
| ':' constant_expression
| declarator ':' constant_expression
;

enum_specifier
: ENUM '{' enumerator_list '}'
| ENUM IDENTIFIER '{' enumerator_list '}'
| ENUM IDENTIFIER
;

enumerator_list
: enumerator
| enumerator_list ',' enumerator
;

enumerator
: IDENTIFIER
| IDENTIFIER '=' constant_expression
;

type_qualifier
: CONST
| VOLATILE
;

declarator
: pointer direct_declarator               { $$ = NOS; }
| direct_declarator                       { $$ = $1; }
;

direct_declarator
: IDENTIFIER					{ $$ = makeid($1); }
| '(' declarator ')'				{ $$ = NOS; }
| direct_declarator '[' constant_expression ']' { $$ = NOS; }
| direct_declarator '[' ']'                     { $$ = NOS; }
| direct_declarator '(' parameter_type_list ')' { $$ = NOS; }
| direct_declarator '(' identifier_list ')'     { $$ = NOS; }
| direct_declarator '(' ')'                     { $$ = makeop('f', 1, $1, NULL, NULL); }
;

pointer
: '*'
| '*' type_qualifier_list
| '*' pointer
| '*' type_qualifier_list pointer
;

type_qualifier_list
: type_qualifier
| type_qualifier_list type_qualifier
;


parameter_type_list
: parameter_list
| parameter_list ',' ELLIPSIS
;

parameter_list
: parameter_declaration
| parameter_list ',' parameter_declaration
;

parameter_declaration
: declaration_specifiers declarator			{ /* fprintf(yyout, "\nPD1\n"); */ }
| declaration_specifiers abstract_declarator		{ /* fprintf(yyout, "\nPD2\n"); */ }
| declaration_specifiers				{ /* fprintf(yyout, "\nPD3\n"); */ }
;

identifier_list
: IDENTIFIER
| identifier_list ',' IDENTIFIER
;

type_name
: specifier_qualifier_list
| specifier_qualifier_list abstract_declarator
;

abstract_declarator
: pointer
| direct_abstract_declarator
| pointer direct_abstract_declarator
;

direct_abstract_declarator
: '(' abstract_declarator ')'
| '[' ']'
| '[' constant_expression ']'
| direct_abstract_declarator '[' ']'
| direct_abstract_declarator '[' constant_expression ']'
| '(' ')'
| '(' parameter_type_list ')'
| direct_abstract_declarator '(' ')'
| direct_abstract_declarator '(' parameter_type_list ')'
;

initializer
: assignment_expression             { $$ = $1; }
| '{' initializer_list '}'          { $$ = NOS; }
| '{' initializer_list ',' '}'      { $$ = NOS; }
;

initializer_list
: initializer
| initializer_list ',' initializer
;

statement
: asm_statement         { $$ = $1; }
| labeled_statement	{ $$ = NOS; }
| compound_statement	{ $$ = $1; }
| expression_statement	{ $$ = $1; }
| selection_statement	{ $$ = $1; }
| iteration_statement	{ $$ = $1; }
| jump_statement	{ $$ = $1; }
;

asm_statement
: ASM '(' argument_expression_list ')'	{ $$ = makeop(ASM, 1, $3, NULL, NULL); }
;

labeled_statement
: IDENTIFIER ':' statement
| CASE constant_expression ':' statement
| DEFAULT ':' statement
;

compound_statement
: '{' '}' 			/* empty function */	{ $$ = NULL; }
| '{' statement_list '}' 	/* normal function */	{ $$ = $2; }
| '{' declaration_list '}'				{ $$ = NOS; }
| '{' declaration_list statement_list '}'		{ $$ = NOS; }
;

declaration_list
: declaration			
| declaration_list declaration
;

statement_list
: statement			{ $$ = $1; }
| statement_list statement	{ $$ = makeop(';', 2, $1, $2, NULL); }
;

expression_statement
: ';'			{ $$ = NULL; }
| expression ';'	{ $$ = makeop('X', 1, $1, NULL, NULL); }
;

selection_statement
: IF '(' expression ')' statement                            { $$ = makeop(IF, 2, $3, $5, NULL); }
| IF '(' expression ')' statement ELSE statement               { $$ = makeop(IF, 3, $3, $5, $7); }
| SWITCH '(' expression ')' statement                                                { $$ = NOS; }
;

iteration_statement
: WHILE '(' expression ')' statement                      { $$ = makeop(WHILE, 2, $3, $5, NULL); }
| DO statement WHILE '(' expression ')' ';'                                          { $$ = NOS; }
| FOR '(' expression_statement expression_statement ')' statement                    { $$ = NOS; }
| FOR '(' expression_statement expression_statement expression ')' statement         { $$ = NOS; }
;

jump_statement
: GOTO IDENTIFIER ';'		{ $$ = NOS; }
| CONTINUE ';'			{ $$ = NOS; }
| BREAK ';'			{ $$ = NOS; }
| RETURN ';'			{ $$ = makeop(RETURN, 0, NULL, NULL, NULL); }
| RETURN expression ';'		{ $$ = makeop(RETURN, 1, $2, NULL, NULL); }
;

source_file
: translation_unit				{ docomp($1); }
;

translation_unit
: external_declaration         			{ $$ = $1; }
| translation_unit external_declaration 	{ $$ = makeop('T', 2, $1, $2, NULL); }
;

external_declaration
: asm_statement ';'             { $$ = $1; }
| function_definition		{ $$ = $1; }
| declaration			{ $$ = $1; }
;

function_definition
: declaration_specifiers declarator declaration_list compound_statement { $$ = NOS; }
| declaration_specifiers declarator compound_statement                  { $$ = makeop('F', 2, $2, $3, NULL); }
| declarator declaration_list compound_statement                        { $$ = NOS; }
| declarator compound_statement                                         { $$ = NOS; }
;

%%

void iddef(Syntree *p)
{
	/*
	char s[1024];
	switch (p->type) {
	case 0:
		return;
	case 1:
		if (symt[p->u.id.id].isnew) {
			sprintf(s, "undefined reference to `%s'", symt[p->u.id.id].name);
			yyerror(s);
		}
		break;
		}
	*/	
}

void initgvars()
{
	int x;

	fprintf(yyout, "\ninit__%s macro\n", basefn);
	for (x = 0; x < symtn; x++) {
		if (symt[x].var)
			fprintf(yyout, "\tinit___%s\n", symt[x].name);
	}
	fprintf(yyout, "\tendm\n");
}

void pushid(Syntree *p, int type)
{
	switch (type) {
	case 1:
		fprintf(yyout, "\tmovf ___%s, W\n", symt[p->u.id.id].name);
		fprintf(yyout, "\tpushw\n");
		break;
	}
}

void pushcon(Syntree *p)
{
	fprintf(yyout, "\tmovlw D'%i'\t\t\n", p->u.con.con);
	fprintf(yyout, "\tpushw\n");
}

void popval(int type)
{
	switch (type) {
	case 1:
		fprintf(yyout, "\tpopw\n");
		break;
	}
}

int evalconstexp(Syntree *p, char *v)
{
	switch (p->type) {
	case 0:
		return p->u.con.con;
	case 1:
		fprintf(stderr, "error: external variable `%s' may be initialized only with a constant expression\n", v);
		exit(1);
	case 2:
		switch (p->u.op.op) {
		case '+':
			return evalconstexp(p->u.op.opa[0], v) +
				evalconstexp(p->u.op.opa[1], v);
		case '-':
			if (p->u.op.opn == 1) /* unary */
				return -evalconstexp(p->u.op.opa[0], v);
			else 
				return evalconstexp(p->u.op.opa[0], v) -
					evalconstexp(p->u.op.opa[1], v);
		case '&':
			return evalconstexp(p->u.op.opa[0], v) &
				evalconstexp(p->u.op.opa[1], v);
		case '^':
			return evalconstexp(p->u.op.opa[0], v) ^
				evalconstexp(p->u.op.opa[1], v);
		case '|':
			return evalconstexp(p->u.op.opa[0], v) |
				evalconstexp(p->u.op.opa[1], v);
		case LEFT_OP:
			return evalconstexp(p->u.op.opa[0], v) <<
				evalconstexp(p->u.op.opa[1], v);
		case RIGHT_OP:
			return evalconstexp(p->u.op.opa[0], v) >>
				evalconstexp(p->u.op.opa[1], v);
		case '!':
			return !evalconstexp(p->u.op.opa[0], v);
		default:
			fprintf(stderr, "error: external variable `%s' initialized using unknown operator\n", v);
		}
	}
	return 0;
}

static Syntree *findlaststatement(Syntree *p)
{
	if (!p)
		return NULL;
	if (p->type == TYPEOP && p->u.op.op == ';')
		return findlaststatement(p->u.op.opa[1]);
	return p;
}

void comp(Syntree *p)
{
	int x;
	Syntree *q;
	char *s;
	
	if (!p)
		return;

	switch (p->type) {
	case 0:
		fprintf(yyout, "\tmovlw D'%d'\n", p->u.con.con);
		fprintf(yyout, "\tpushw\n");
		break;
	case 1:
		fprintf(yyout, "\tmovf ___%s, W\n", symt[p->u.id.id].name);
		fprintf(yyout, "\tpushw\n");
/*		fprintf(yyout, "; ID (%s)\n", symt[p->u.id.id].name); */
/*
		fprintf(yyout, "\tcall ___%s\n", symt[p->u.id.id].name);
		popval(1);
*/
		break;
	case 2:
		switch (p->u.op.op) {
		case ASM:
			fprintf(yyout, "\t%s\n", symt[p->u.op.opa[0]->u.id.id].name);
/*			fprintf(yyout, "\tpushw\n"); */
			break;
		case 'C':
			if (p->u.op.opn > 1) {
				fprintf(stderr, "error: function arguments not currently supported\n");
				exit(1);
			}
			fprintf(yyout, "\tcall ___%s\n", symt[p->u.op.opa[0]->u.id.id].name);
			break;
			/*
		case 'C':
			if (!strcmp(symt[p->u.op.op[0]->u.id.id].name, "__asm__")) {
				fprintf(yyout, "\t%s\n", symt[p->u.op.op[1]->u.id.id].name);
				fprintf(yyout, "\tpushw\n");
			} else {
				if (p->u.op.opn > 1) {
					fprintf(stderr, "error: function arguments not currently supported\n");
					exit(1);
				}
				fprintf(yyout, "\tcall ___%s\n", symt[p->u.op.op[0]->u.id.id].name);
			}
			break;
			*/
		case 'F':
			s = symt[p->u.op.opa[0]->u.op.opa[0]->u.id.id].name;
			fprintf(yyout, "\n___%s\n", s);
			if (!strcmp("main", s)) {
				fprintf(yyout, "\tgeneralinit\n");
				fprintf(yyout, "\tcall initgvars\n");
			}
			comp(p->u.op.opa[1]);

			q = findlaststatement(p->u.op.opa[1]);
			if (!q || q->type != TYPEOP || q->u.op.op != RETURN) {
				fprintf(yyout, "\tpushw\t\t\t\t; implicit return value (undefined)\n");  /* undefined */
				fprintf(yyout, "\treturn\t\t\t\t; implicit return\n");
			} else {
				fprintf(yyout, "\t;pushw\t\t\t\t; implicit return value (dead code)\n");
				fprintf(yyout, "\t;return\t\t\t\t; implicit return (dead code)\n");
				fprintf(yyout, "; because of\n");
				dumptree(q);
			}
			break;
		case 'X':
			comp(p->u.op.opa[0]);
			fprintf(yyout, "\tdrop\t\t\t\t; end of expression statement\n");
			break;
		case ',':
			comp(p->u.op.opa[0]);
			fprintf(yyout, "\tdrop\t\t\t\t; comma operator, dropping expression\n");
			comp(p->u.op.opa[1]);
			break;
		case ';':
			if (p->u.op.opa[0]) {
				comp(p->u.op.opa[0]);
/*				if (p->u.op.opa[0]->type != 2 || p->u.op.opa[0]->u.op.op != ';')
				fprintf(yyout, "\tdrop\n"); */
			}
			if (p->u.op.opn > 1 && p->u.op.opa[1]) {
				comp(p->u.op.opa[1]);
/*				if (p->u.op.opa[1]->type != 2 || p->u.op.opa[1]->u.op.op != ';')
				fprintf(yyout, "\tdrop\n"); */
			}
			break;
		case 'T':
			comp(p->u.op.opa[0]);
			if (p->u.op.opn > 1)
				comp(p->u.op.opa[1]);
			break;
		case '=':
			comp(p->u.op.opa[1]);
/*			fprintf(yyout, "\tmovlw D'%d'\n", p->u.op.op[1]->u.con); */
			fprintf(yyout, "\tpeekw\n");
			fprintf(yyout, "\tmovwf ___%s\n", symt[p->u.op.opa[0]->u.id.id].name);
			break;
		case '&':
			comp(p->u.op.opa[0]);
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tpopw\n");
			fprintf(yyout, "\tandwf INDF, F\n");
			break;
		case '^':
			comp(p->u.op.opa[0]);
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tpopw\n");
			fprintf(yyout, "\txorwf INDF, F\n");
			break;
		case '|':
			comp(p->u.op.opa[0]);
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tpopw\n");
			fprintf(yyout, "\tiorwf INDF, F\n");
			break;
		case '+':
			comp(p->u.op.opa[0]);
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tpopw\n");
			fprintf(yyout, "\taddwf INDF, F\n");
			break;
		case '-':
			comp(p->u.op.opa[0]);
			if (p->u.op.opn == 1) { /* unary */
				fprintf(yyout, "\tcomf INDF, F\n");
				fprintf(yyout, "\tincf INDF, F\n");
			} else {
				comp(p->u.op.opa[1]);
				fprintf(yyout, "\tpopw\n");
				fprintf(yyout, "\tsubwf INDF, F\n");
			}
			break;
		case LEFT_OP:
			comp(p->u.op.opa[0]);
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tcall shiftleft\n");
			break;
		case RIGHT_OP:
			comp(p->u.op.opa[0]);
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tcall shiftright\n");
			break;
		case '!':
			comp(p->u.op.opa[0]);
			fprintf(yyout, "\tcall logicnot\n");
			break;
		case AND_OP:
			x = labelcount++;
			fprintf(yyout, "\t\t\t\t\t; begin logical AND operator\n");
			comp(p->u.op.opa[0]);
			fprintf(yyout, "\tmovf INDF, F\n");
			fprintf(yyout, "\tbtfsc STATUS, Z\n");
			fprintf(yyout, "\tgoto endand%i%s\n", x, basefn);
			fprintf(yyout, "\tdrop\n");
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tmovf INDF, F\n");
			fprintf(yyout, "\tbtfsc STATUS, Z\n");
			fprintf(yyout, "\tgoto endand%i%s\n", x, basefn);
			fprintf(yyout, "\tmovlw 0x01\n");
			fprintf(yyout, "\tmovwf INDF\n");
			fprintf(yyout, "endand%i%s\n", x, basefn);
			break;
		case OR_OP:
			x = labelcount++;
			fprintf(yyout, "\t\t\t\t\t; begin logical OR operator\n");
			comp(p->u.op.opa[0]);
			fprintf(yyout, "\tmovf INDF, F\n");
			fprintf(yyout, "\tbtfss STATUS, Z\n");
			fprintf(yyout, "\tgoto ortrue%i%s\n", x, basefn);
			fprintf(yyout, "\tdrop\n");
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tmovf INDF, F\n");
			fprintf(yyout, "\tbtfsc STATUS, Z\n");
			fprintf(yyout, "\tgoto endor%i%s\n", x, basefn);
			fprintf(yyout, "ortrue%i%s\n", x, basefn);
			fprintf(yyout, "\tmovlw 0x01\n");
			fprintf(yyout, "\tmovwf INDF\n");
			fprintf(yyout, "endor%i%s\n", x, basefn);
			break;
		case EQ_OP:
			x = labelcount++;
			comp(p->u.op.opa[0]);
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tcall equal\n");
			break;
		case INC_OP:
			if (p->u.op.opa[0]->type == TYPEID) {
				fprintf(yyout, "\tincf ___%s, F\n", symt[p->u.op.opa[0]->u.id.id].name);
				comp(p->u.op.opa[0]);
			} else {
				/* can't handle any other lvalue types */
			}
			break;
		case DEC_OP:
			if (p->u.op.opa[0]->type == TYPEID) {
				fprintf(yyout, "\tdecf ___%s, F\n", symt[p->u.op.opa[0]->u.id.id].name);
				comp(p->u.op.opa[0]);
			} else {
				/* can't handle any other lvalue types */
			}
			break;
		case ADD_ASSIGN:
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tpopw\n");
			fprintf(yyout, "\taddwf ___%s, F\n", symt[p->u.op.opa[0]->u.id.id].name);
			fprintf(yyout, "\tmovf ___%s, W\n", symt[p->u.op.opa[0]->u.id.id].name);
			fprintf(yyout, "\tpushw\n");
			break;
		case SUB_ASSIGN:
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tpopw\n");
			fprintf(yyout, "\tsubwf ___%s, F\n", symt[p->u.op.opa[0]->u.id.id].name);
			fprintf(yyout, "\tmovf ___%s, W\n", symt[p->u.op.opa[0]->u.id.id].name);
			fprintf(yyout, "\tpushw\n");
			break;
		case RETURN:
/*			evalexp(p->u.op.op[0], 1); */ /* always int for
						      now */
			comp(p->u.op.opa[0]);
			/*popval(1);*/
			/*
			if (p->u.op.opn > 0) {
				fprintf(yyout, "\tmovlw %d\n", p->u.op.op[0]->u.con);
			}
			*/
			/* we probably need to check here for
			 * "return;" and insert a pushw. */
			fprintf(yyout, "\treturn\n");
			break;
		case 'D':
			switch (p->u.op.opa[0]->type) {
			case 1:
				/*
				fprintf(yyout, "\n___%s\tequ\tuservar + %i\n",
					symt[p->u.op.op[0]->u.id.id].name,
					nextgvar++);
				*/
				fprintf(yyout, "\n___%s\tEQU\tnextvar\n",
					symt[p->u.op.opa[0]->u.id.id].name);
				fprintf(yyout, "\tVARIABLE nextvar=___%s + 1\n",
					symt[p->u.op.opa[0]->u.id.id].name);


				
				fprintf(yyout, "\ninit___%s macro\n", symt[p->u.op.opa[0]->u.id.id].name);
				if (p->u.op.opn > 1) {
					fprintf(yyout, "\tmovlw D'%i'\n", evalconstexp(p->u.op.opa[1],
										    symt[p->u.op.opa[0]->u.id.id].name));
				} else { 
					fprintf(yyout, "\tmovlw D'0'\n");
				}
				fprintf(yyout, "\tmovwf ___%s\n", symt[p->u.op.opa[0]->u.id.id].name);
				fprintf(yyout, "\tendm\n");
				fprintf(yyout, "\n");
				symt[p->u.op.opa[0]->u.id.id].var = 1;
				break;
			case 2:
				switch (p->u.op.opa[0]->u.op.op) {
				case 'f': /* function prototype, do
					     nothing */
					fprintf(yyout, "\n; function prototype declared: %s()\n\n",
						symt[p->u.op.opa[0]->u.op.opa[0]->u.id.id].name);
					break;
				}
				break;
			default:
				yyerror("internal parse error");
			}
			break;
		case WHILE:
			x = labelcount++;
			fprintf(yyout, "while%i%s\t\t\t\t; begin WHILE statement\n", x, basefn);
			comp(p->u.op.opa[0]);
			fprintf(yyout, "\tpopw\n");
			fprintf(yyout, "\tmovwf x\n");
			fprintf(yyout, "\tmovf x, F\n");
			fprintf(yyout, "\tbtfsc STATUS, Z\n");
			fprintf(yyout, "\tgoto endwhi%i%s\n", x, basefn);
			comp(p->u.op.opa[1]);
			fprintf(yyout, "\tgoto while%i%s\n", x, basefn);
			fprintf(yyout, "endwhi%i%s\n", x, basefn);
			break;
		case IF:
			fprintf(yyout, "\t\t\t\t\t; begin IF statement\n");
			x = labelcount++;
			comp(p->u.op.opa[0]);
			fprintf(yyout, "\tpopw\n");
			fprintf(yyout, "\tmovwf x\n");
			fprintf(yyout, "\tmovf x, F\n");
			fprintf(yyout, "\tbtfsc STATUS, Z\n");
			fprintf(yyout, "\tgoto else%i%s\n", x, basefn);
			comp(p->u.op.opa[1]);
			if (p->u.op.opn == 3)
				fprintf(yyout, "\tgoto endif%i%s\n", x, basefn);
			fprintf(yyout, "else%i%s\n", x, basefn);
			if (p->u.op.opn == 3)
				comp(p->u.op.opa[2]);
			fprintf(yyout, "endif%i%s\n", x, basefn);
			break;
		}
	}
}

void docomp(Syntree *p)
{
	fprintf(yyout, "\n");
	comp(p);
	tree = p;
}

void rmsuffix(char *fn, char *base)
{
	char *p;
	strcpy(base, fn);
	if (p = strchr(base, '.'))
		*p = '\0';
	return;
}

void cexit(int status)
{
	exit(status);
}

int yyerror(char *s)
{
	fflush(stdout);
	fprintf(stderr, "%s:%i: error: parse error before \"%s\" (%s)\n", parsefile, line, yytext, s);
	cexit(1);
	return 0;
}

void yycompile(Opt *opt, char *ifn, char *ofn)
{
	rmsuffix(ifn, basefn);
	
	yyin = fopen(ifn, "r");
	yyout = fopen(ofn, "w");
	do {
		yyparse();
	} while (!feof(yyin));

	initgvars(); /* this uses basefn */
	dumptree(tree);
	
	fclose(yyout);
	fclose(yyin);
}
