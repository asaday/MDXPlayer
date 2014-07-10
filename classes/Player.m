//
//  Player.m
//  mdxplayer
//
//  Created by asada on 2013/04/03.
//  Copyright (c) 2013 asada. All rights reserved.
//
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "Player.h"
#include "mxdrvg.h"

#import "CFileManager.h"

@interface Player ()
-(void)callback:(AudioQueueRef)inAQ buffer:(AudioQueueBufferRef)inBuffer;
@end


static void MAudioQueueOutputCallback(void *inUserData, AudioQueueRef inAQ, AudioQueueBufferRef  inBuffer)
{
	Player *p = (__bridge Player *)(inUserData);
	[p callback:inAQ buffer:inBuffer];
}

#define FOCOUNT (9*1000)		// 大体・・
#define INBLKSIZE	1024		// max=1024 in MXDRV real-bytes = this * 2(2ch) * 2(16bit)  1024/44.1KHz about 23msec

@implementation Player
{
	int playfadeout;
	int playduration;
	int playend;
	AudioQueueRef audioQueue;
    AudioQueueBufferRef quebuf[3];
    
    NSArray *files;
    int fileIndex;
 
    NSMutableData* mdx;
    NSMutableData* pdx;
    int mutecount;
}

-(void)dealloc
{
    MXDRVG_End();
    AudioQueueStop(audioQueue, true);
    AudioQueueDispose(audioQueue, true);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(id)init
{
    self = [super init];
    [self initAudio];
    return self;
}


#pragma mark Audio

-(void)initAudio
{
//    AudioSessionInitialize(NULL, NULL, NULL, NULL);
//	UInt32 sc = kAudioSessionCategory_MediaPlayback;
//	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sc), &sc);
//	AudioSessionSetActive(true);
    
	AVAudioSession *session = [AVAudioSession sharedInstance];
	[session setActive:YES error:nil];
	[session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    
	AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = 44100.0;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 2;
    audioFormat.mBitsPerChannel     = 16;
    audioFormat.mBytesPerPacket     = 4;
    audioFormat.mBytesPerFrame      = 4;
    audioFormat.mReserved           = 0;
    
    AudioQueueNewOutput(&audioFormat, MAudioQueueOutputCallback, (__bridge void *)(self), NULL, NULL, 0, &audioQueue);
}

-(void)callback:(AudioQueueRef)inAQ buffer:(AudioQueueBufferRef)inBuffer
{
    int playat = MXDRVG_GetPlayAt();

	
	int cnt = inBuffer->mAudioDataBytesCapacity / (INBLKSIZE*4);

	int sptime = 1;
	if(_speedup) sptime = 10;

	for(int spcnt = 0; spcnt < sptime; spcnt++)	// ホントはこのループはいらないの、スピードアップ用
	{
		SWORD *ptr = (SWORD*)inBuffer->mAudioData;
		for(int i = 0 ; i < cnt ; i++)
		{
			if(!MXDRVG_GetTerminated()) MXDRVG_GetPCM(ptr , INBLKSIZE);
			ptr += INBLKSIZE * 2;
		}
	}

	
    
	//	MXDRVのフェードアウト使うとPCMがもどってこないのと、ADPCMは音量調整できなくてアレだったからfadeoutしないのでAudioQueueでやってみる
	//	if(!playfadeout && playduration && playat > playduration - FOCOUNT)
	//	{
	//		MXDRVG_Fadeout();
	//		playfadeout = 1;
	//	}
	

	// 手動fadeout
	if(playat > playduration - FOCOUNT)
	{
		float v = (float)(playduration - playat) / FOCOUNT;
		if(v > 1.0) v = 1.0;
		if(v < 0.0) v = 0.0;
		AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, v);
		if(v < 0.05) memset(inBuffer->mAudioData, 0, INBLKSIZE * cnt * 4); // 念のため末尾では無音データにしておく
	}

	
	// test sound...
//    for(int i = 0 ;i < 3 ; i+=4){
//        ptr[i] = 0;
//        ptr[i+1] = 0;
//        ptr[i+2] = 0xffff;
//        ptr[i+3] = 0x7fff;
//    }

    
	inBuffer->mAudioDataByteSize = INBLKSIZE * cnt * 4;
	inBuffer->mPacketDescriptionCount = INBLKSIZE * cnt * 2;
	AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    
	
	if(!playend && (MXDRVG_GetTerminated() || playat > playduration))
    {
        playend = 1;
		
		AudioQueuePause(inAQ); // backgroundで止めると次の再生がおかしい場合があるので一時停止で AudioQueueStop(inAQ, false);
		
		// どうもisMainで無いようなので一応main回し
		dispatch_async(dispatch_get_main_queue(), ^{
			//[self seekPlayingNext];
			[self performSelector:@selector(seekPlayingNext) withObject:nil afterDelay:1];
		});
	}
}

#pragma mark MDX

#define NSEnCodingJapaneseMacOS -2147483647
#define NSEnCodingJapaneseISO2022JP2 -2147481567
#define NSEnCodingJapaneseISO2022JP1 -2147481566
#define NSEnCodingJapaneseShiftJIS -2147481087

#define S2UTBL0_SIZE (256*sizeof(unsigned short))
#define S2UTBL1_SIZE (60*188*sizeof(unsigned long))

// x68kの機種依存コード教えて・・
// 機種依存はいるとiOSの変換ではコケるので意地でも通す版
+(NSString*)force_sjis2utf8:(NSData*)src
{
	if(src == nil) return nil;
	
	unsigned short *s2utbl0;
	unsigned long *s2utbl1;
    
	FILE *fp = fopen([[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"s2utbl.dat"] UTF8String], "rb");
	if(fp == NULL) return nil;
	
	s2utbl0 = malloc(S2UTBL0_SIZE);
	s2utbl1 = malloc(S2UTBL1_SIZE);
	if(s2utbl0 == NULL || s2utbl1 == NULL)
	{
		if(s2utbl0) free(s2utbl0);
		if(s2utbl1) free(s2utbl1);
		return nil;
	}
	fread(s2utbl0, 1, S2UTBL0_SIZE, fp);
	fread(s2utbl1, 1, S2UTBL1_SIZE, fp);
	fclose(fp);
	
	NSMutableData *dst = [NSMutableData dataWithCapacity:[src length]*2];
	int i,k;
	unsigned long c,f;
	unsigned char *p;
	int len;
	
	p = (unsigned char*)[src bytes];
	len = [src length];
	
	for(i = 0 ; i < len ; i++)
	{
		c = s2utbl0[p[i]];
		if((c & 0xff00) == 0x0100 && i < len -1)
		{
			k = p[++i] - 0x40;
			if(k >= 0x40) k--;
			if(k >= 0 && k < 188)
			{
				k += (c & 0xff) * 188;
				c = s2utbl1[k];
				if(c >= 0x10000)
				{
					f = 0xd800 | (c >> 10);
					[dst appendBytes:&f length:2];
				}
			}
		}
		[dst appendBytes:&c length:2];
	}
	
	c = 0;
	[dst appendBytes:&c length:2];
	
	free(s2utbl0);
	free(s2utbl1);
	
	return [NSString stringWithCharacters:[dst bytes] length:[dst length]/2];
}

+(NSString*)titleForMDXData:(NSData*)mdxt
{
	if (mdxt == nil) return nil;
    const unsigned char *mdxptr = mdxt.bytes;
	
	int pos;
	for(pos = 0 ; pos < mdxt.length ; pos++)
		if (mdxptr[pos+0] == 0x0d && mdxptr[pos+1] == 0x0a) break;
    
	if (pos >= mdxt.length) return nil;
	
    NSData *tdat = [mdxt subdataWithRange:NSMakeRange(0,pos)];
	
    NSString *title = nil;
    title = [[NSString alloc] initWithData:tdat encoding:NSShiftJISStringEncoding];
    if(!title) title = [[NSString alloc] initWithData:tdat encoding:NSUTF8StringEncoding];
    if(!title) title = [[NSString alloc] initWithData:tdat encoding:NSEnCodingJapaneseShiftJIS];
    if(!title) title = [Player force_sjis2utf8:tdat];
    
    return title;
}

+(NSString*)titleForMDXFile:(NSString*)file
{
	NSData* mdxt = [NSMutableData dataWithContentsOfFile:file];
	return [Player titleForMDXData:mdxt];
}


// retrn {mdx:data, pdx:data}
-(NSDictionary*)loadMDXPDX:(NSString*)file
{
	_title = @"";
	
	NSData* mdxt = [CFileMnager dataOfFile:file];
	if (mdxt == nil)
    {
        return NO;
    }
    const unsigned char *mdxptr = mdxt.bytes;
	
	int pos;
	for(pos = 0 ; pos < mdxt.length ; pos++)
		if (mdxptr[pos+0] == 0x0d && mdxptr[pos+1] == 0x0a) break;

	if (pos >= mdxt.length) return nil;

	int titleEndPos = pos;

	for( ; pos < mdxt.length ; pos++)
		if (mdxptr[pos] == 0x1a) break;

    if (pos >= mdxt.length) return nil;

	int pdxStartPos = pos;
	for( ; pos < mdxt.length ; pos++)
		if (mdxptr[pos] == 0x00) break;
    
	if (pos >= mdxt.length) return nil;
	pdxStartPos++;
	int pdxEndPos = pos;
	
	pos++;
	int mdxBodyStartPos = pos;
	int mdxBodySize = mdxt.length-mdxBodyStartPos;

    NSData *tdat = [mdxt subdataWithRange:NSMakeRange(0,titleEndPos)];
    
	NSString *title = nil;
    title = [[NSString alloc] initWithData:tdat encoding:NSShiftJISStringEncoding];
    if(!title) title = [[NSString alloc] initWithData:tdat encoding:NSUTF8StringEncoding];
    if(!title) title = [Player force_sjis2utf8:tdat];
    
    _title = title;
	
    NSString* mdxPath = [file stringByDeletingLastPathComponent];

    NSData *pdxt = nil;
    
	if (pdxEndPos-pdxStartPos > 0)
    {
		NSString *f = [[NSString alloc] initWithData:[mdxt subdataWithRange:NSMakeRange(pdxStartPos,pdxEndPos-pdxStartPos)] encoding:NSShiftJISStringEncoding];
        if(f)
        {
            if(![f.lowercaseString hasSuffix:@".pdx"]) f = [f stringByAppendingString:@".pdx"];
            pdxt = [CFileMnager dataOfFile:[mdxPath stringByAppendingPathComponent:f]];
            if(!pdxt) pdxt = [CFileMnager dataOfFile:[mdxPath stringByAppendingPathComponent:f.lowercaseString]];
            if(!pdxt) pdxt = [CFileMnager dataOfFile:[mdxPath stringByAppendingPathComponent:f.uppercaseString]];
        }
    }
	
	NSData *mdxr = [mdxt subdataWithRange:NSMakeRange(mdxBodyStartPos,mdxBodySize)];

	if(pdxt) return @{@"mdx":mdxr, @"pdx":pdxt};
	return @{@"mdx":mdxr};
}

-(void)prepareMXDRV:(NSData*)mdxt pdx:(NSData*)pdxt
{
	if(!mdxt) return;

	MXDRVG_End();
    MXDRVG_Start(44100, 0, 64*1024, 1024*1024);
	MXDRVG_TotalVolume(256);

	unsigned char mdxData[10];
	mdxData[0] = 0x00;
	mdxData[1] = 0x00;
	mdxData[2] = (unsigned char)(pdxt ? 0 : 0xff);
	mdxData[3] = (unsigned char)(pdxt ? 0 : 0xff);
	mdxData[4] = 0x00;
	mdxData[5] = 0x0a;
	mdxData[6] = 0x00;
	mdxData[7] = 0x08;
	mdxData[8] = 0x00;
	mdxData[9] = 0x00;
	
	unsigned char pdxData[10];
	pdxData[0] = 0x00;
	pdxData[1] = 0x00;
	pdxData[2] = 0x00;
	pdxData[3] = 0x00;
	pdxData[4] = 0x00;
	pdxData[5] = 0x0a;
	pdxData[6] = 0x00;
	pdxData[7] = 0x02;
	pdxData[8] = 0x00;
	pdxData[9] = 0x00;
	
	mdx = [NSMutableData dataWithBytes:mdxData length:10];
    [mdx appendData:mdxt];

	if (pdxt)
    {
        pdx = [NSMutableData dataWithBytes:pdxData length:10];
		[pdx appendData:pdxt];
		MXDRVG_SetData((char*)mdx.bytes, mdx.length, (char*)pdx.bytes, pdx.length);
	}
    else
    {
		MXDRVG_SetData((char*)mdx.bytes, mdx.length, NULL, 0);
	}
	
}


-(void)startPlay:(BOOL)wantstop
{

	// file読み込みのクラウド考慮でdispatch
	dispatch_async([CFileMnager cfque], ^{

		NSString *file = [files objectAtIndex:fileIndex];
		NSDictionary *r = [self loadMDXPDX:file];
		
		if(!r)
		{
			int i;
			for(i = 1 ; i < files.count ; i++)
			{
				fileIndex = (fileIndex + 1) % files.count;
				file = [files objectAtIndex:fileIndex];
				r = [self loadMDXPDX:file];
				if(r && [r objectForKey:@"mdx"]) break;
			}
			if(i == files.count) return;
		}
		if(!r) return;

		dispatch_async(dispatch_get_main_queue(), ^{
         //   backでとめると次がとぼけるときがあるので止めない・・ AudioQueueStop(audioQueue, true);
            
            if(wantstop) AudioQueueStop(audioQueue, YES);

            _paused = NO;
            playend = 0;
            playfadeout = 0;
            playduration = 0;
            mutecount = 0;
            
			NSData *mdxt = [r objectForKey:@"mdx"];
			NSData *pdxt = [r objectForKey:@"pdx"];
			
			[self prepareMXDRV:mdxt pdx:pdxt];
			
			_file = file;
			
			int lc = _loopcount;
			if(lc < 1 || lc > 100) lc = 1;
			
			
			playduration = MXDRVG_MeasurePlayTime(lc, 0) + FOCOUNT;    // nofadeout + 8sec
			_duration = playduration;
			MXDRVG_PlayAt(0, lc, 1);
			
            // MXDRVG_CALLBACK_OPMINT = MXDRVG_MeasurePlayTime_OPMINT;
            //playatではこっちが外され、、ここからではとどかないので概算でいくです
            // ホントはgetworkでポインタ持ってcallbackを指定しOPMINITもどきで計算すべきです
            
            
            if(wantstop)
            {
                //stopでbuffer-clearされるそうなので作る
                //stopしていない場合こわいので頭貯めずに走ってみる
                for (int i = 0; i < 3 ; i++)
                {
                    AudioQueueBufferRef buf;// = quebuf[i];
                    AudioQueueAllocateBuffer(audioQueue, INBLKSIZE * 4 * 4, &buf); // capacity *4
                    [self callback:audioQueue buffer:buf];
                }
			}
            
			// for spring board display
			NSDictionary *info = @{MPMediaItemPropertyTitle:_title,
						  MPMediaItemPropertyAlbumArtist: [file lastPathComponent],
						  MPMediaItemPropertyAlbumTitle: [[file lastPathComponent] lastPathComponent]
						  };
			
			
			[[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:info];
			
			AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
			AudioQueueStart(audioQueue, NULL);
		});
		
	});
	
}


-(float)volume
{
    return MXDRVG_GetTotalVolume() / 255.0;
}

-(void)setVolume:(float)volume
{
    MXDRVG_TotalVolume(volume * 255.0);
}

#pragma mark reference interface


-(int)current
{
    int p = MXDRVG_GetPlayAt();
    return p;
}

-(NSArray*)files
{
    return files;
}

-(int)nowIndex
{
    return fileIndex;
}

-(void)seekPlayingNext
{
	fileIndex = (fileIndex + 1) % files.count;
	[self startPlay:NO];
}

#pragma mark action interface

-(void)pause:(BOOL)p
{
    if(p) AudioQueuePause(audioQueue);
    else AudioQueueStart(audioQueue, NULL);
    
    _paused = p;
}

// seekNext,Prevは操作からくるのでforeだからstopかけてもよさそう

-(void)playFile:(NSString*)file
{
    [self playFiles:@[file] start:0];
}

-(void)playFiles:(NSArray*)ifiles start:(int)index
{
    if(!ifiles || !ifiles.count) return;
    files = ifiles;
    fileIndex = index;
    [self startPlay:YES];
}

-(void)seekNext
{
    fileIndex = (fileIndex + 1) % files.count;
    [self startPlay:YES];
}

-(void)seekPrev
{
    fileIndex = (fileIndex + files.count -1) % files.count;
    [self startPlay:YES];
}

-(void)seekIndex:(int)index
{
    if(index > files.count) return;
    fileIndex = index;
    [self startPlay:YES];
}

@end

