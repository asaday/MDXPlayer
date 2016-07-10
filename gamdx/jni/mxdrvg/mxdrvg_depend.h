// MXDRVG.DLL X68000-depend header
// Copyright (C) 2000 GORRY.

#ifndef __MXDRVG_DEPEND_H__
#define __MXDRVG_DEPEND_H__

typedef uint8_t UBYTE;
typedef uint16_t UWORD;
typedef uint32_t ULONG;
typedef int8_t SBYTE;
typedef int16_t SWORD;
typedef int32_t SLONG;

typedef int64_t LONGLONG;
typedef unsigned long UPTRLONG;
// long that matches the size of pointer

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
    UPTRLONG d0;
    UPTRLONG d1;
    UPTRLONG d2;
    UPTRLONG d3;
    UPTRLONG d4;
    UPTRLONG d5;
    UPTRLONG d6;
    UPTRLONG d7;
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
