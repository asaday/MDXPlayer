// MXDRVG.DLL header
// Copyright (C) 2000 GORRY.

#ifndef __MXDRVG_H__
#define __MXDRVG_H__

#include "mxdrvg_depend.h"

typedef struct tagMXDRVG_WORK_CH {
	UBYTE volatile *S0000;	// Ptr
	UBYTE S0004_b;	// PCM bank
	UBYTE volatile *S0004;	// voice ptr
	ULONG S0008;	// bend delta
	ULONG S000c;	// bend offset
	UWORD S0010;	// D
	UWORD S0012;	// note+D
	UWORD S0014;	// note+D+bend+Pitch LFO offset
	UBYTE S0016;	// flags b3=keyon/off
	UBYTE S0017;	// flags
	UBYTE S0018;	// ch
	UBYTE S0019;	// carrier slot
	UBYTE S001a;	// len
	UBYTE S001b;	// gate
	UBYTE S001c;	// p
	UBYTE S001d;	// keyon slot
	UBYTE S001e;	// Q
	UBYTE S001f;	// Keyon delay
	UBYTE S0020;	// Keyon delay counter
	UBYTE S0021;	// PMS/AMS
	UBYTE S0022;	// v
	UBYTE S0023;	// v last
	UBYTE S0024;	// LFO delay
	UBYTE S0025;	// LFO delay counter
	UBYTE volatile *S0026;	// Pitch LFO Type
	ULONG S002a;	// Pitch LFO offset start
	ULONG S002e;	// Pitch LFO delta start
	ULONG S0032;	// Pitch LFO delta
	ULONG S0036;	// Pitch LFO offset
	UWORD S003a;	// Pitch LFO length (cooked)
	UWORD S003c;	// Pitch LFO length
	UWORD S003e;	// Pitch LFO length counter
	UBYTE volatile *S0040;	// Volume LFO Type
	UWORD S0044;	// Volume LFO delta start
	UWORD S0046;	// Volume LFO delta (cooked)
	UWORD S0048;	// Volume LFO delta
	UWORD S004a;	// Volume LFO offset
	UWORD S004c;	// Volume LFO length
	UWORD S004e;	// Volume LFO length counter
} MXDRVG_WORK_CH;

typedef struct tagMXDRVG_WORK_GLOBAL {
	UWORD L001ba6;
	ULONG L001ba8;
	UBYTE volatile *L001bac;
	UBYTE L001bb4[16];
	UBYTE L001df4;
	UBYTE L001df6[16];
	UWORD L001e06;	// Channel Mask (true)
	UBYTE L001e08;
	UBYTE L001e09;
	UBYTE L001e0a;
	UBYTE L001e0b;
	UBYTE L001e0c;	// @t
	UBYTE L001e0d;
	UBYTE L001e0e;
	UBYTE L001e10;
	UBYTE L001e12;	// Paused
	UBYTE L001e13;	// End
	UBYTE L001e14;	// Fadeout Offset
	UBYTE L001e15;
	UBYTE L001e17;	// Fadeout Enable
	UBYTE L001e18;
	UBYTE L001e19;
	UWORD L001e1a;	// Channel Enable
	UWORD L001e1c;	// Channel Mask
	UWORD L001e1e[2];	// Fadeout Speed
	UWORD L001e22;
	UBYTE volatile *L001e24;
	UBYTE volatile *L001e28;
	UBYTE volatile *L001e2c;
	UBYTE volatile *L001e30;
	UBYTE volatile *L001e34;
	UBYTE volatile *L001e38;
	ULONG L00220c;
	UBYTE volatile *L002218;
	UBYTE volatile *L00221c;
	ULONG L002220; // L_MDXSIZE
	ULONG L002224; // L_PDXSIZE
	UBYTE volatile *L002228;	// voice data
	UBYTE volatile *L00222c;
	UBYTE L002230;
	UBYTE L002231;
	UBYTE L002232;
	UBYTE L002233[9];
	UBYTE L00223c[12];
	UBYTE L002245;
	UWORD L002246; // loop count
	ULONG FATALERROR;
	ULONG FATALERRORADR;
	ULONG PLAYTIME; // 演奏時間((PLAYTIME*1024/4000)msec == (PLAYTIME*256)μsec)
	UBYTE MUSICTIMER;  // 演奏時間タイマー定数
	UBYTE STOPMUSICTIMER;  // 演奏時間タイマー停止
	ULONG MEASURETIMELIMIT; // 演奏時間計測中止時間
	ULONG SAMPRATE; // サンプリングレート
	ULONG INNERSAMPRATE; // サンプリングレート
	UBYTE OPMFILTER; // OPMの高域フィルタ
	ULONG PLAYSAMPLES; // 生成したサンプル数
} MXDRVG_WORK_GLOBAL;

typedef struct tagMXDRVG_WORK_KEY {
	UBYTE OPT1;
	UBYTE OPT2;
	UBYTE SHIFT;
	UBYTE CTRL;
	UBYTE XF3;
	UBYTE XF4;
	UBYTE XF5;
} MXDRVG_WORK_KEY;

typedef UBYTE MXDRVG_WORK_OPM[256];

typedef void MXDRVG_CALLBACK MXDRVG_CALLBACK_OPMINTFUNC( void );

enum {
	MXDRVG_WORKADR_FM = 0,		// FM8ch+PCM1ch
	MXDRVG_WORKADR_PCM,			// PCM7ch
	MXDRVG_WORKADR_GLOBAL,
	MXDRVG_WORKADR_KEY,
	MXDRVG_WORKADR_OPM,
	MXDRVG_WORKADR_PCM8,
	MXDRVG_WORKADR_CREDIT,
	MXDRVG_WORKADR_OPMINT,
};

#ifndef MXDRVG_EXPORT
#define MXDRVG_EXPORT
#endif

#ifdef __cplusplus
extern "C" {
#endif

#ifndef __MXDRVG_LOADMODULE

MXDRVG_EXPORT
int MXDRVG_Start(
	int samprate,
	int fastmode,
	int mdxbufsize,
	int pdxbufsize
);

MXDRVG_EXPORT
void MXDRVG_End(
	void
);

MXDRVG_EXPORT
int MXDRVG_GetPCM(
	SWORD *buf,
	int len
);

MXDRVG_EXPORT
void MXDRVG_SetData(
	void *mdx,
	ULONG mdxsize,
	void *pdx,
	ULONG pdxsize
);

MXDRVG_EXPORT
void volatile *MXDRVG_GetWork(
	int i
);

MXDRVG_EXPORT
void MXDRVG(
	X68REG *reg
);

MXDRVG_EXPORT
ULONG MXDRVG_MeasurePlayTime(
	int loop,
	int fadeout
);

MXDRVG_EXPORT
void MXDRVG_PlayAt(
	ULONG playat,
	int loop,
	int fadeout
);

MXDRVG_EXPORT
ULONG MXDRVG_GetPlayAt(
	void
);

MXDRVG_EXPORT
int MXDRVG_GetTerminated(
	void
);

MXDRVG_EXPORT
void MXDRVG_TotalVolume(
	int vol
);

MXDRVG_EXPORT
int MXDRVG_GetTotalVolume(
	void
);

MXDRVG_EXPORT
void MXDRVG_ChannelMask(
	int mask
);

MXDRVG_EXPORT
int MXDRVG_GetChannelMask(
	void
);

#endif // __MXDRVG_LOADMODULE

#ifdef __cplusplus
}
#endif // __cplusplus

#define MXDRVG_Call( a )				\
{									\
	X68REG reg;						\
									\
	reg.d0 = (a);					\
	reg.d1 = 0x00;					\
	MXDRVG( &reg );					\
}									\
									

#define MXDRVG_Call_2( a, b )		\
{									\
	X68REG reg;						\
									\
	reg.d0 = (a);					\
	reg.d1 = (b);					\
	MXDRVG( &reg );					\
}									\
									

#define MXDRVG_Replay() MXDRVG_Call( 0x0f )
#define MXDRVG_Stop() MXDRVG_Call( 0x05 )
#define MXDRVG_Pause() MXDRVG_Call( 0x06 )
#define MXDRVG_Cont() MXDRVG_Call( 0x07 )
#define MXDRVG_Fadeout() MXDRVG_Call_2( 0x0c, 19 )
#define MXDRVG_Fadeout2(a) MXDRVG_Call_2( 0x0c, (a) )



#endif //__MXDRVG_H__
