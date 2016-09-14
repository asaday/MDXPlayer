//
//  SpeanaBitmap.m
//  mdxplayer
//
//  Created by sinn246 on 2016/05/08.
//  Copyright © 2016年 asada. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "SpeanaBitmap.h"
#include "trackinfo.h"

static UInt32* _buf = 0;
static UInt32* _BG = 0;

#define SPEA_HOLD 10

static UInt16 SPEA_BF1[32+10+10];//ほんとは４２＋５で十分かと

static UInt16 SPEA_MAX[32];
static UInt16 SPEA_NOW[32];
static UInt16 SPEA_VAL[32];
static UInt16 SPEA_TIMER[32];

static UInt16 ROUTE[] = {	0,1,4,9,16,24,35,47,61,77,94,
  113,133,155,179,204,230,258,287,317,348,
  381,415,450,486,523,561,600,65535};

static UInt8 RISE_TABLE_N[] =  {1,1,2,2,4,4,4,4,8,8,8,8,8,8,8,
  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8};

static CGColorSpaceRef colorSpace = 0;
static void doDraw();

#define BX 32
#define BY 32
#define DARKCOLOR 0xff402020
#define LIGHTCOLOR 0xffff7070
#define MAXCOLOR 0xff775050

CGImageRef makeSpeanaMaskBitmap()
{
  if(!_BG){
    _BG = malloc(BX*8 * BY*2 * 4);
    UInt32* p = _BG;
    int x,y;
    for(y=0;y<BY;y++){
      for(x=0;x<BX;x++){//奇数行は１ドット黒・７ドット透明
        *p++ =0xff000000;
        *p++ =0x00000000;
        *p++ =0x00000000;
        *p++ =0x00000000;
        *p++ =0x00000000;
        *p++ =0x00000000;
        *p++ =0x00000000;
        *p++ =0x00000000;
      }
      for(x=0;x<BX*8;x++){//偶数行は全て黒
        *p++ =0xff000000;
      }
    }
  }
  if(!colorSpace) colorSpace = CGColorSpaceCreateDeviceRGB();
  CGDataProviderRef provider = CGDataProviderCreateWithData(nil,_BG,BX*8 * BY*2 * 4 ,nil);
  CGImageRef image = CGImageCreate(BX*8, BY*2, 8, 32, BX*8*4, colorSpace, kCGImageAlphaLast | kCGBitmapByteOrder32Big
                                   ,provider, NULL, FALSE, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  return image;
}

CGImageRef makeSpeanaBitmap(BOOL doPaint)
{
  if(!_buf){
    _buf = malloc(BX * BY * 4);
  }
  if(doPaint){
    // paint inside _buf here
    doDraw();
  }else{
    for(int d=0; d<BY*BX; d++){
      _buf[d] =  DARKCOLOR;
    }
  }
  // make CGImageRef
  if(!colorSpace) colorSpace = CGColorSpaceCreateDeviceRGB();
  CGDataProviderRef provider = CGDataProviderCreateWithData(nil,_buf,BX * BY * 4 ,nil);
  CGImageRef image = CGImageCreate(BX, BY, 8, 32, BX*4, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big
                                   ,provider, NULL, FALSE, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  return image;
}

static void PSET(int x,int y, UInt32 col){
  _buf[x+y*BX] = col;
}

void doDraw()
{
  //SPEANA_DISP
  TRACKINFO* T = shared_TRACKINFO;
  int i;
  for(i=0;i<52;i++) SPEA_BF1[i]=0;
  
  for(i=0;i<8;i++,T++){
    if(~T->KEYONSTAT & T->KEYONCHANGE){  //この辺のロジックはMMDSPそのまま
      int d = ((int)T->KEYCODE + T->KEYOFFSET)/3;
      if(d<42){
        int x = T->VELOCITY;
        SPEA_BF1[d] += x;
        if(d>0){SPEA_BF1[d-1] += (x*3)/4;}
        SPEA_BF1[d+1] += (x*3)/4;
        if(d>1){SPEA_BF1[d-2] += (x*5)/16;}
        SPEA_BF1[d+2] += (x*5)/16;
        if(d>2){SPEA_BF1[d-3] += x/8;}
        SPEA_BF1[d+3] += x/8;
        if(d>3){SPEA_BF1[d-4] += x/4;}
        SPEA_BF1[d+4] += x/4;
        if(d>4){SPEA_BF1[d-5] += x/16;}
        SPEA_BF1[d+5] += x/16;
      }
    }
  }
  //以下はMMDSPのソースをかなり参考にしたがよくわかりにくいところが多く意訳しました。
  UInt16* a0 = SPEA_BF1+5;
  UInt16 d0_w;
  for(i=0;i<32;i++){
    SPEA_VAL[i]=0;
    if((d0_w = *a0++)){// 値が０なら何もしない
      for(int j=0;j<sizeof(ROUTE);j++){
        if (d0_w < ROUTE[j]) {//ROUTEというのがテーブルになっていて擬似的に対数変換している感じ（ルートとなっているので平方根とっているつもりかもしれないが）
          if(SPEA_NOW[i]<j) SPEA_VAL[i] = j;
          break;
        }
      }
    }
    if(SPEA_VAL[i]>SPEA_NOW[i]){  //NOWは現在の値、VALが目標値
      SPEA_NOW[i] += RISE_TABLE_N[ SPEA_VAL[i]-SPEA_NOW[i] ]; //急に上がるときは最大で８までに抑える
    }else if(SPEA_VAL[i]<SPEA_NOW[i]){
      int d=SPEA_NOW[i]-SPEA_VAL[i];
      SPEA_NOW[i] -= (d>2)?2:d;  //下がるときも2まで
    }
    if(SPEA_TIMER[i]>0){
      SPEA_TIMER[i] -= 1;
    }
    if(SPEA_TIMER[i]==0){
      if(SPEA_MAX[i]>0) SPEA_MAX[i] -= 1;  //タイマーが切れたらMAX棒が下に１ずつ落ちる
    }
    if(SPEA_MAX[i] < SPEA_VAL[i]){  //目標値がMAXを超えたら更新、タイマーは最高値を保持する時間（コマ数）
      SPEA_MAX[i] = SPEA_VAL[i];
      SPEA_TIMER[i] = SPEA_HOLD;
    }
    for(int y=0; y<BY; y++){
      PSET(i, y, (SPEA_NOW[i]<(BY-y))?DARKCOLOR:LIGHTCOLOR);
    }
    if(SPEA_MAX[i]>0) PSET(i, (BY-SPEA_MAX[i]),MAXCOLOR);
  }
}
