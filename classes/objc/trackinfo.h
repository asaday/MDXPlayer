//
//  trackinfo.h - ported from MMDSP.h of MMDSP
//  mdxplayer
//
//  Created by sinn246 on 2016/05/05.
//  Copyright © 2016年 asada. All rights reserved.
//

#ifndef trackinfo_h
#define trackinfo_h


typedef struct tagTRACKINFO{
  UInt8 STCHANGE;//  .ds.b	1	*ステータス変化フラグ(bit0-3)
  //  *bit0:音源種類 & TRACKNO
  //  *bit1:BEND
  //  *bit2:PAN
  //  *bit3:PROGRAM
  UInt8 KEYONCHANGE;//:	.ds.b	1	*キーＯＮ状態変化フラグ
  UInt8 VELCHANGE;//:	.ds.b	1	*ベロシティ変化フラグ
  UInt8 KEYCHANGE;//:	.ds.b	1	*キーコード変化フラグ
  
  UInt8 INSTRUMENT;//:	.ds.b	1	*0:音源の種類(0:none 1:FM 2:ADPCM 3:MIDI)
  UInt8 CHANNEL;//:	.ds.b	1	*音源のチャンネル番号(OPM1-8,ADPCM1-8,MIDI1-32)
  UInt16 KEYOFFSET;//:	.ds.w	1	*KEYCODEのMIDIコードとの差
  UInt16 BEND;//:		.ds.w	1	*1:ベンド
  UInt16 PAN;//:		.ds.w	1	*2:パン
  volatile UInt8* PROGRAM;//:	.ds.w	1	*3:プログラム
  UInt16 KEYONSTAT;//:	.ds.b	1	*キーＯＮ状態(bit0-7 0:keyon 1:keyoff)
  UInt8 TRACKNO;//:	.ds.b	1	*トラック番号
  UInt8 KEYCODE;//:	.ds.b	8	*キーコード
  UInt8 VELOCITY;//:	.ds.b	8	*ベロシティ
  
  //  *==================================================
  //  *トラック情報（その他）
  //  *==================================================
  
  UInt16 KBS_CHG;//:	.ds.w	1	*チェックフラグ（変化したパラメータのビットが立つ）
  
  UInt8 KBS_MP;//:		.ds.b	1	*C:ＭＰ　のＯＮ／ＯＦＦ
  UInt8 KBS_MA;//:		.ds.b	1	*D:ＭＡ
  UInt8 KBS_MH;//:		.ds.b	1	*E:ＭＨ
  
  UInt8 KBS_k;//:		.ds.b	1	*0:ｋ
  UInt8 KBS_q;//:		.ds.b	1	*1:ｑ(bit7: @vフラグ)
  //  .ds.b	1
  
  UInt16 KBS_D;//:		.ds.w	1	*2345:ＤＰＢＡの現在の値
  UInt16 KBS_P;//:		.ds.w	1
  UInt16 KBS_B;//:		.ds.w	1
  UInt16 KBS_A;//:		.ds.w	1
  
  volatile UInt8* KBS_PROG;//:	.ds.w	1	*6:＠
  
  UInt8 KBS_TL1;//:	.ds.b	1	*7:＠ｖ
  UInt8 KBS_TL2;//:	.ds.b	1	*8:変化後の＠ｖ
  
  volatile UInt8*  KBS_DATA;//:	.ds.l	1	*9:ＤＡＴＡ
  
  UInt16 KBS_KC1;//:	.ds.w	1	*A:ＫＣ
  UInt16 KBS_KC2;//:	.ds.w	1	*B:変化後
} TRACKINFO;

//// Interface

void renewTRACKINFO();
extern TRACKINFO* shared_TRACKINFO;

#endif /* trackinfo_h */
