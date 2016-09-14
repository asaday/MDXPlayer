//
//  KeyboardBitmap.m
//  mdxplayer
//
//  Created by sinn246 on 2016/05/05.
//  Copyright © 2016年 asada. All rights reserved.
//

#import "KeyboardBitmap.h"
#include "trackinfo.h"

static UInt32* _buf = 0;
static UInt32* _BG = 0;
static int KeyON[8];
CGColorSpaceRef colorSpace = 0;

static void makeInitialBitmap();
static void makeLamp();


void initKeyboardBitmap()
{
  for(int i=0;i<8;i++)  KeyON[i] = 0;
}

CGImageRef makeKeyboardBitmap(BOOL doPaint)
{
  if(_buf == 0){
    _buf = malloc(BS_X * BS_Y * 4);
    for(int i=0;i<BS_X*BS_Y; i++){
      _buf[i] = 0xff000000;
    }
    makeInitialBitmap();
    _BG = _buf;
    _buf = malloc(BS_X * BS_Y * 4);
  }
  memcpy(_buf,_BG,BS_X * BS_Y * 4);
  
  // paint inside _buf here
  if(doPaint) {
    makeLamp();
  }
  
  // make CGImageRef
  if(!colorSpace) colorSpace = CGColorSpaceCreateDeviceRGB();
  CGDataProviderRef provider = CGDataProviderCreateWithData(nil,_buf,BS_X * BS_Y * 4 ,nil);
  CGImageRef image = CGImageCreate(BS_X, BS_Y, 8, 32, BS_X*4, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big
                                   ,provider, NULL, FALSE, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  return image;
}




/////////////////

UInt32* addr(int x,int y)
{
  return _buf+BS_X*y + x;
}

void putAt(int x,int y,UInt8* PCG,size_t size)
{
  UInt8 d;
  for(UInt32* p = addr(x,y); size>0; size-=4,p+=BS_X){
    for(int i=0; i<4; i++){
      if((d = *PCG++)){ // skip if 0
        d = (d-1)*31 + 4;
        p[i] = (0xff<<24) + (d<<16) + (d<<8) + d;
      }
      
    }
  }
}

void putAtC(int x,int y,UInt8* PCG,size_t size,UInt8* col)
{
  UInt8 d;
  for(UInt32* p = addr(x,y); size>0; size-=4,p+=BS_X){
    for(int i=0; i<4; i++){
      if((*PCG++)){ // skip if 0
        p[i] = (0xff<<24) + (col[2]<<16) + (col[1]<<8) + col[0];
      }
    }
  }
}

// 4-dot PCG  0 is transparent 1 black - 9 white

static UInt8 KeyCF[] =
{
  9,9,0,0,
  9,9,0,0,
  9,9,0,0,
  9,9,0,0, //4
  9,9,0,0,
  9,9,0,0,
  9,9,0,0,
  9,9,0,0, //8
  9,9,0,0,
  9,9,6,0,
  9,9,6,0,
  9,9,6,0, //12
  9,9,6,0,
  9,9,6,0,
  9,9,6,0,
  6,6,6,0, //16
};

static UInt8 KeyDGA[] =
{
  0,9,0,0,
  0,9,0,0,
  0,9,0,0,
  0,9,0,0, //4
  0,9,0,0,
  0,9,0,0,
  0,9,0,0,
  0,9,0,0, //8
  0,9,0,0,
  9,9,6,0,
  9,9,6,0,
  9,9,6,0, //12
  9,9,6,0,
  9,9,6,0,
  9,9,6,0,
  6,6,6,0, //16
};

static UInt8 KeyEB[] =
{
  0,9,6,0,
  0,9,6,0,
  0,9,6,0,
  0,9,6,0, //4
  0,9,6,0,
  0,9,6,0,
  0,9,6,0,
  0,9,6,0, //8
  0,9,6,0,
  9,9,6,0,
  9,9,6,0,
  9,9,6,0, //12
  9,9,6,0,
  9,9,6,0,
  9,9,6,0,
  6,6,6,0, //16
};

static UInt8 KeyHalf[] =
{
  3,1,0,0,
  3,1,0,0,
  3,1,0,0,
  3,1,0,0, //4
  3,1,0,0,
  3,1,0,0,
  4,1,0,0,
  4,3,0,0, //8
  4,1,0,0,
};

static void makeInitialBitmap()
{
  int x,y;
  for(int ch = 0; ch<8; ch++){
    y = ch * KEYB_HEIGHT;
    for(int octave = 0; octave<8;octave++){
      x = octave * 4*7;
      putAt(x,y,KeyEB,sizeof(KeyEB)); //E
      putAt(x+4,y,KeyCF,sizeof(KeyCF)); //F
      putAt(x+6,y,KeyHalf,sizeof(KeyHalf)); //F#
      putAt(x+8,y,KeyDGA,sizeof(KeyDGA)); //G
      putAt(x+10,y,KeyHalf,sizeof(KeyHalf)); //G#
      putAt(x+12,y,KeyDGA,sizeof(KeyDGA)); //A
      putAt(x+14,y,KeyHalf,sizeof(KeyHalf)); //A#
      putAt(x+16,y,KeyEB,sizeof(KeyEB)); //B
      putAt(x+20,y,KeyCF,sizeof(KeyCF)); //C
      putAt(x+22,y,KeyHalf,sizeof(KeyHalf)); //C#
      putAt(x+24,y,KeyDGA,sizeof(KeyDGA)); //D
      putAt(x+26,y,KeyHalf,sizeof(KeyHalf)); //D#
    }
  }
}

static void makeLamp(){
  TRACKINFO* tif = shared_TRACKINFO;
  UInt8 d0_b;
  UInt16 d0_w;
  int x,y;
  UInt8 col[] = {0,255,0};

  for(int track = 0; track < 8; track++){
    //put_keylamp
    if(~tif[track].KEYONSTAT & (tif[track].KEYCHANGE | tif[track].KEYONCHANGE)) KeyON[track] = 1;
    else if(tif[track].KEYONSTAT & tif[track].KEYONCHANGE) KeyON[track] = 0;
    if(KeyON[track]){
      d0_w = tif[track].KEYCODE + (tif[track].KEYOFFSET-15) -1 ; // in my system key0 is E but mmdsp D#
      if(d0_w >=0 && d0_w < 96){
        x = (d0_w / 12) * 4 * 7;
        y = KEYB_HEIGHT * track;
        switch(d0_w % 12){
          case 0:putAtC(x,y,KeyEB,sizeof(KeyEB),col);break; //E
          case 1:putAtC(x+4,y,KeyCF,sizeof(KeyCF),col);break; //F
          case 2:putAtC(x+6,y,KeyHalf,sizeof(KeyHalf),col);break; //F#
          case 3:putAtC(x+8,y,KeyDGA,sizeof(KeyDGA),col);break; //G
          case 4:putAtC(x+10,y,KeyHalf,sizeof(KeyHalf),col);break; //G#
          case 5:putAtC(x+12,y,KeyDGA,sizeof(KeyDGA),col);break; //A
          case 6:putAtC(x+14,y,KeyHalf,sizeof(KeyHalf),col);break; //A#
          case 7:putAtC(x+16,y,KeyEB,sizeof(KeyEB),col);break; //B
          case 8:putAtC(x+20,y,KeyCF,sizeof(KeyCF),col);break; //C
          case 9:putAtC(x+22,y,KeyHalf,sizeof(KeyHalf),col);break; //C#
          case 10:putAtC(x+24,y,KeyDGA,sizeof(KeyDGA),col);break; //D
          case 11:putAtC(x+26,y,KeyHalf,sizeof(KeyHalf),col);break; //D#
        }
      }
    }
    //BEND
    UInt8 colB[] = {0,255,63};
    if((tif[track].KEYONSTAT&1)==0){
      if(tif[track].STCHANGE&2||tif[track].KEYONCHANGE||tif[track].KEYCHANGE){
        d0_w = tif[track].KEYCODE + (tif[track].KEYOFFSET-15) -1 ; // in my system key0 is E but mmdsp D#
        d0_w += tif[track].BEND >> 6;
        //この後BENDの値で少し補正が入るが・・・
        if(d0_w >=0 && d0_w < 96){
          x = (d0_w / 12) * 4 * 7;
          y = KEYB_HEIGHT * track;
          switch(d0_w % 12){
            case 0:putAtC(x,y,KeyEB,sizeof(KeyEB),colB);break; //E
            case 1:putAtC(x+4,y,KeyCF,sizeof(KeyCF),colB);break; //F
            case 2:putAtC(x+6,y,KeyHalf,sizeof(KeyHalf),colB);break; //F#
            case 3:putAtC(x+8,y,KeyDGA,sizeof(KeyDGA),colB);break; //G
            case 4:putAtC(x+10,y,KeyHalf,sizeof(KeyHalf),colB);break; //G#
            case 5:putAtC(x+12,y,KeyDGA,sizeof(KeyDGA),colB);break; //A
            case 6:putAtC(x+14,y,KeyHalf,sizeof(KeyHalf),colB);break; //A#
            case 7:putAtC(x+16,y,KeyEB,sizeof(KeyEB),colB);break; //B
            case 8:putAtC(x+20,y,KeyCF,sizeof(KeyCF),colB);break; //C
            case 9:putAtC(x+22,y,KeyHalf,sizeof(KeyHalf),colB);break; //C#
            case 10:putAtC(x+24,y,KeyDGA,sizeof(KeyDGA),colB);break; //D
            case 11:putAtC(x+26,y,KeyHalf,sizeof(KeyHalf),colB);break; //D#
          }
        }
        
      }
    }
  }
}

  
  
  
  