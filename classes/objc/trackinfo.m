//
//  trackinfo.m - ported from MXCTRL.s of MMDSP
//  mdxplayer
//
//  Created by sinn246 on 2016/05/05.
//  Copyright © 2016年 asada. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "trackinfo.h"
#include "mxdrvg.h"

TRACKINFO* shared_TRACKINFO = 0;

#define TRACKUPDATE(A,B,C)     if(TI->A!=B){TI->A=B;TI->STCHANGE|=1<<C;}
#define KEYUPDATE(A,B,C)     if(TI->A!=FM->B){TI->A=FM->B;TI->KBS_CHG|=1<<C;}
#define FM_CHANNELS 8
#define TOTAL_CHANNELS 8

void renewTRACKINFO()
{
  MXDRVG_WORK_GLOBAL* G = (MXDRVG_WORK_GLOBAL*)MXDRVG_GetWork(MXDRVG_WORKADR_GLOBAL);
  MXDRVG_WORK_CH *FM =  (MXDRVG_WORK_CH*)MXDRVG_GetWork(MXDRVG_WORKADR_FM);
  if(shared_TRACKINFO==0){
    shared_TRACKINFO = calloc(sizeof(TRACKINFO), TOTAL_CHANNELS);
  }
  TRACKINFO* TI = shared_TRACKINFO;
  
  UInt8 d0_b;
  UInt16 d0_w;
  int i;
  
  for(int ch = 0; ch < FM_CHANNELS; (ch++,TI++,FM++)){
    TI->KBS_CHG = 0;
    // ignore KBS_MP,MA,MH because they are never used
    KEYUPDATE(KBS_k, S001f, 0);
    KEYUPDATE(KBS_q, S001e, 1);
    KEYUPDATE(KBS_D, S0010, 2);
    KEYUPDATE(KBS_P, S0036, 3);
    KEYUPDATE(KBS_B, S000c, 4);
    // S004a is defined as UWORD but in MMDSP  it is accessed as BYTE
    // and then negated and sign extended, to make KBS_A. ignoring it.
    KEYUPDATE(KBS_A, S004a, 5);
    KEYUPDATE(KBS_PROG, S0004, 6);
    // KBS_@v1 and @v2 are sometimes negative? but igonore it
    KEYUPDATE(KBS_TL1, S0022, 7);
    KEYUPDATE(KBS_TL2, S0023, 8);
    KEYUPDATE(KBS_DATA, S0004, 9);
    KEYUPDATE(KBS_KC1, S0012, 0xA);
    KEYUPDATE(KBS_KC2, S0014, 0xB);
    
    TI->STCHANGE = 0;
    TI->KEYOFFSET = 15;   // OFFSETが初期化ルーチンで１５に設定されているのに気づくのに２週間かかりました
    SInt16* pS0010 = (SInt16*)&(FM->S0010); //S0010 が負の値になることに気づくのに２日かかりました

    d0_w = FM->S0014 - FM->S0012 + *pS0010;
    TRACKUPDATE(BEND, d0_w, 1);
    d0_w = (UInt16)(FM->S001c >> 6); // original sourcecode is tricky but it just get top 2 bits
    TRACKUPDATE(PAN, d0_w, 2);
    TRACKUPDATE(PROGRAM, FM->S0004, 3)
    d0_b = G->L00223c[ch];
    G->L00223c[ch] |= 0x80;
    if((0x80 & d0_b) == 0){
      TI->KEYONCHANGE = 1;
      if(d0_b & 0x78){
        TI->KEYONSTAT = 0xfe;
      }else{
        TI->KEYONSTAT = 0xff;
      }
    }
    i = FM->S0012 - *pS0010 - 5;
    if(i<0) i=0;
    d0_b = (UInt8)(i >> 6);
    if(TI->KEYCODE != d0_b){
      TI->KEYCODE = d0_b;
      TI->KEYCHANGE = 1;
    }else{
//      TI->KEYCHANGE = 0;  // added by SN
    }
    d0_b = (UInt8)(-(int)FM->S0023 + 0x7f);
    if(TI->VELOCITY != d0_b){
      TI->VELOCITY = d0_b;
      TI->VELCHANGE = 1;
    }else{
//      TI->VELCHANGE = 0;  //added by SN
    }
  }
}
