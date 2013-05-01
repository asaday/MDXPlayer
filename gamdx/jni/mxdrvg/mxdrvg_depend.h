// MXDRVG.DLL X68000-depend header
// Copyright (C) 2000 GORRY.

#ifndef __MXDRVG_DEPEND_H__
#define __MXDRVG_DEPEND_H__

typedef unsigned char UBYTE;
typedef unsigned short UWORD;
typedef unsigned long ULONG;
typedef signed char SBYTE;
typedef signed short SWORD;
typedef signed long SLONG;

typedef long long LONGLONG;
#define TEXT(a) (a)
typedef char TCHAR;

typedef SWORD MXDRVG_SAMPLETYPE;
typedef MXDRVG_SAMPLETYPE Sample;

#if !defined(MXDRVG_CALLBACK)
#define MXDRVG_CALLBACK
#endif

#define FALSE 0
#define TRUE 1

typedef struct __X68REG {
    ULONG d0;
    ULONG d1;
    ULONG d2;
    ULONG d3;
    ULONG d4;
    ULONG d5;
    ULONG d6;
    ULONG d7;
    UBYTE *a0;
    UBYTE *a1;
    UBYTE *a2;
    UBYTE *a3;
    UBYTE *a4;
    UBYTE *a5;
    UBYTE *a6;
    UBYTE *a7;
} X68REG;

#define SET 255
#define CLR 0
#define GETBWORD(a) ((((UBYTE *)(a))[0]*256)+(((UBYTE *)(a))[1]))
#define GETBLONG(a) ((((UBYTE *)(a))[0]*16777216)+(((UBYTE *)(a))[1]*65536)+(((UBYTE *)(a))[2]*256)+(((UBYTE *)(a))[3]))
#define PUTBWORD(a,b) ((((UBYTE *)(a))[0]=(UBYTE)((b)>> 8)),(((UBYTE *)(a))[1]=(UBYTE)((b)>> 0)))
#define PUTBLONG(a,b) ((((UBYTE *)(a))[0]=(UBYTE)((b)>>24)),(((UBYTE *)(a))[1]=(UBYTE)((b)>>16)), (((UBYTE *)(a))[2]=(UBYTE)((b)>> 8)), (((UBYTE *)(a))[3]=(UBYTE)((b)>> 0)))










#endif //__MXDRVG_DEPEND_H__
