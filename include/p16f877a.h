#ifndef _P16F877A_H
#define _P16F877A_H

/*
 *  Memory outside of bank 0 cannot currently be accessed from C,
 *  because switching to another bank will disrupt access to the stack
 *  which is used to evaluate expressions.  Memory outside of bank 0
 *  must be accessed using assembly language to avoid C trying to use
 *  the stack during the process.  For this reason, PIC registers are
 *  not exposed to C and can be accessed only through the get...() and
 *  set...() macros or assembly language.  Once support for pointers
 *  is added, we will be able to define variables to access registers
 *  directly, for example:
 * 
 *    int *PPORTB = (int *) 6;
 *    #define PORTB (*PPORTB)
 *    etc.
 *
 *  Pointers will handle bank switching automatically.
 */

/*
extern int __asmtemp;  (The parser doesn't yet know how to handle this.)
*/

extern int __setportb();
extern int __settrisb();

#define  setportb(X)  (__asmtemp = X, __setportb())
#define  settrisb(X)  (__asmtemp = X, __settrisb())

extern int getportb();
extern int gettrisb();

extern int delay100us();
extern int delay1ms();
extern int delay10ms();

#endif
