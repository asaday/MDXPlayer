#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <assert.h>

#if !defined(__FMXDRVG_PCM8_GLOBAL_H__)
#define __FMXDRVG_PCM8_GLOBAL_H__



#define PCM8_NCH 8  // É`ÉÉÉìÉlÉãêî


static int dltLTBL[48+1]= {
	16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,
	73,80,88,97,107,118,130,143,157,173,190,209,230,253,279,307,
	337,371,408,449,494,544,598,658,724,796,876,963,1060,1166,1282,1411,1552,
};
static int DCT[16]= {
	-1,-1,-1,-1,2,4,6,8,
	-1,-1,-1,-1,2,4,6,8,
};

static int ADPCMRATETBL[2][4] = {
	2, 3, 4, 4,
	0, 1, 2, 2,
};
static int ADPCMRATEADDTBL[8] = {
	46875, 62500, 93750, 125000, 15625*12, 15625*12, 15625*12, 0,
};
static int PCM8VOLTBL[16] = {
	2,3,4,5,6,8,10,12,16,20,24,32,40,48,64,80,
};


#endif  // __FMXDRVG_PCM8_GLOBAL_H__


// [EOF]
