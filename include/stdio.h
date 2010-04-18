#ifndef _STDIO_H
#define _STDIO_H

extern int __putchar();

#define  putchar(X)  (__asmtemp = X, __putchar())

#endif
