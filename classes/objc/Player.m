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
#import <pthread.h>

#import "Player.h"
#include "mxdrvg.h"

#import "KeyboardBitmap.h"
#import "SpeanaBitmap.h"
#import "trackinfo.h"
#import "lzx042.h"

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
    int playduration;
    BOOL playend;
    BOOL first;
    NSInteger oldsec;
    
    NSArray *files;
    NSInteger fileIndex;
    
    AudioQueueRef audioQueue;
    AudioQueueBufferRef quebuf[3];
    
    NSMutableData* mdx;
    NSMutableData* pdx;
    
    void* mdx_lzxbuf;
    void* pdx_lzxbuf;
    
    float volume;
}


#pragma mark MDX

#define NSEnCodingJapaneseMacOS -2147483647
#define NSEnCodingJapaneseISO2022JP2 -2147481567
#define NSEnCodingJapaneseISO2022JP1 -2147481566
#define NSEnCodingJapaneseShiftJIS -2147481087

#define S2UTBL0_SIZE (256*sizeof(UInt16))
#define S2UTBL1_SIZE (60*188*sizeof(UInt32))

static SWORD intermediateBuffer[INBLKSIZE*2*2];//バッファオーバーラン対策に倍のサイズで中間バッファを作っておく
static pthread_mutex_t mxdrv_mutex;

+(void)prepareMask:(CALayer*)layer {
    CGImageRef spemask = makeSpeanaMaskBitmap();
    layer.contents = CFBridgingRelease(spemask);
}


+(void)redrawKey:(CALayer*)keyLayer speana:(CALayer*)speanaLayer paint:(BOOL)paint
{
    renewTRACKINFO();
    CGImageRef keycg = makeKeyboardBitmap(paint);
    CGImageRef specg = makeSpeanaBitmap(paint);
    dispatch_async(dispatch_get_main_queue(), ^{
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        keyLayer.contents = CFBridgingRelease(keycg);
        speanaLayer.contents = CFBridgingRelease(specg);
        [CATransaction commit];
    });
}

// x68kの機種依存コード教えて・・
// 機種依存はいるとiOSの変換ではコケるので意地でも通す版


+(NSString*)force_sjis2utf8:(NSData*)src
{
    static NSData *s2utbl = nil;
    if(src == nil) return nil;
    
    if(s2utbl == nil) s2utbl = [NSData dataWithContentsOfFile:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"s2utbl.dat"]];
    
    if(s2utbl == nil) return nil;
    
    UInt16 *s2utbl0 = (UInt16*)s2utbl.bytes;
    UInt32 *s2utbl1 = (UInt32*)(s2utbl.bytes + S2UTBL0_SIZE);
    
    NSMutableData *dst = [NSMutableData dataWithCapacity:[src length]*2];
    int i,k;
    UInt32 c,f;
    UInt8 *p;
    NSInteger len;
    
    p = (UInt8*)[src bytes];
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


+ (Player*)sharedInstance {
    static Player* _instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[Player alloc] init];
        pthread_mutex_init(&mxdrv_mutex,NULL);
    });
    return _instance;
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
    mdx_lzxbuf = 0;
    pdx_lzxbuf = 0;
    
    _samplingRate = [[NSUserDefaults standardUserDefaults] integerForKey:@"samplingRate"];
    if(_samplingRate == 0) _samplingRate = 44100;
    
    _loopCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"loopCount"];
    if(_loopCount == 0) _loopCount = 2;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(RouteChanged:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(Interrupted:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(remote:) name:@"REMOTE" object:nil];
    
    
    [self initAudio];
    
    [[MPRemoteCommandCenter sharedCommandCenter].playCommand addTarget:self action:@selector(doPlay)];
    [[MPRemoteCommandCenter sharedCommandCenter].pauseCommand addTarget:self action:@selector(doPause)];
    [[MPRemoteCommandCenter sharedCommandCenter].togglePlayPauseCommand addTarget:self action:@selector(togglePause)];
    [[MPRemoteCommandCenter sharedCommandCenter].nextTrackCommand addTarget:self action:@selector(goNext)];
    [[MPRemoteCommandCenter sharedCommandCenter].previousTrackCommand addTarget:self action:@selector(goPrev)];
    return self;
}

-(void)setSamplingRate:(NSInteger)samplingRate	// 44100 22050 48000 62500
{
    files = nil;
    MXDRVG_End();
    AudioQueuePause(audioQueue);
    AudioQueueStop(audioQueue, true);
    AudioQueueFlush(audioQueue);
    AudioQueueDispose(audioQueue, true);
    
    _samplingRate = samplingRate;
    [self initAudio];
    
    [[NSUserDefaults standardUserDefaults] setInteger:_samplingRate forKey:@"samplingRate"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

-(void)setLoopCount:(NSInteger)loopCount
{
    _loopCount = loopCount;
    [[NSUserDefaults standardUserDefaults] setInteger:_loopCount forKey:@"loopCount"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Audio

-(void)initAudio
{
    //    AudioSessionInitialize(NULL, NULL, NULL, NULL);
    //	UInt32 sc = kAudioSessionCategory_MediaPlayback;
    //	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sc), &sc);
    //	AudioSessionSetActive(true);
    
    volume = 1.0;
    
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    
    AudioStreamBasicDescription audioFormat;
    audioFormat.mSampleRate         = _samplingRate;
    audioFormat.mFormatID           = kAudioFormatLinearPCM;
    audioFormat.mFormatFlags        = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    audioFormat.mFramesPerPacket    = 1;
    audioFormat.mChannelsPerFrame   = 2;
    audioFormat.mBitsPerChannel     = 16;
    audioFormat.mBytesPerPacket     = 4;
    audioFormat.mBytesPerFrame      = 4;
    audioFormat.mReserved           = 0;
    
    AudioQueueNewOutput(&audioFormat, MAudioQueueOutputCallback, (__bridge void *)(self), NULL, NULL, 0, &audioQueue);
    first = YES;
    _paused = YES;
}

-(void) RouteChanged:(NSNotification*) note
{
    NSDictionary* dict = note.userInfo;
    int reason = [dict[AVAudioSessionRouteChangeReasonKey] intValue];
    if(reason == AVAudioSessionRouteChangeReasonOldDeviceUnavailable){
        // イヤホンを抜いた時 Bluetoothとの接続が切れた時　ポーズしないと本体から大きな音が出ることあり
        [self pause:YES];
    }
}

-(void) Interrupted:(NSNotification*) note
{
    static BOOL pausedByInterruption = NO;
    NSDictionary* dict = note.userInfo;
    int reason = [dict[AVAudioSessionInterruptionTypeKey] intValue];
    if(reason == AVAudioSessionInterruptionTypeBegan && _file != nil && _paused == NO){
        [self pause:YES];
        pausedByInterruption = YES;
    }else if(reason == AVAudioSessionInterruptionTypeEnded){
        AVAudioSession* theSession = [AVAudioSession sharedInstance];
        NSError* err;
        [theSession setActive:YES error:&err];
        if(pausedByInterruption){
            [self pause:NO];
            pausedByInterruption = NO;
        }
    }
}

-(void)callback:(AudioQueueRef)inAQ buffer:(AudioQueueBufferRef)inBuffer
{
    int playat = MXDRVG_GetPlayAt();
    
    int cnt = inBuffer->mAudioDataBytesCapacity / (INBLKSIZE*4);
    
    int sptime = 1;
    if(_speedup) sptime = 10;
    
    if(!playend && pthread_mutex_trylock(&mxdrv_mutex)==0){
        for(int spcnt = 0; spcnt < sptime; spcnt++)	// ホントはこのループはいらないの、スピードアップ用
        {
            SWORD *ptr = (SWORD*)inBuffer->mAudioData;
            for(int i = 0 ; i < cnt ; i++)
            {
                if(!MXDRVG_GetTerminated()){
                    MXDRVG_GetPCM(intermediateBuffer , INBLKSIZE); //GetPCMがオーバーランすることがあるので中間バッファを使う
                    memcpy(ptr, intermediateBuffer, INBLKSIZE*2*2);//オーバーランした分はどうなるんでしょう？その分のデータは今は捨てていることになる?
                }else{
                    memset(ptr,0, INBLKSIZE*2*2);//ここでゼロクリアしておかないと雑音がなります
                }
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
        
        pthread_mutex_unlock(&mxdrv_mutex);
    }else{//playend=YES
        memset(inBuffer->mAudioData, 0, INBLKSIZE * cnt * 4);
    }
    
    
    inBuffer->mAudioDataByteSize = INBLKSIZE * cnt * 4;
    inBuffer->mPacketDescriptionCount = INBLKSIZE * cnt * 2;
    AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    
    NSInteger sec = playat / 1000;
    if(oldsec != sec){
        oldsec = sec;
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate didChangeSecond];
        });
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^{
        [_delegate didChangeStatus];
    });
    
    
    if(!playend && (MXDRVG_GetTerminated() || playat > playduration))
    {
        playend = YES;
        
        //sinn246:ここでPauseすると表示も止まってしまうので、とめずに無音で鳴らしておく　そのほうが次の曲とのつながりもよい。
        //AudioQueuePause(inAQ); // backgroundで止めると次の再生がおかしい場合があるので一時停止で AudioQueueStop(inAQ, false);
        
        // どうもisMainで無いようなので一応main回し
        dispatch_async(dispatch_get_main_queue(), ^{ // todo: 1sec
            [_delegate didEnd];
            if(files != nil){
                fileIndex = (fileIndex + 1) % files.count;
                [self playOneFile:files[fileIndex]];
            }
        });
    }
}



// retrn {mdx:data, pdx:data}
-(NSDictionary*)loadMDXPDX:(NSString*)file
{
    _title = @"";
    
    NSData* mdxt = [NSData dataWithContentsOfFile:file];
    if (mdxt == nil)
    {
        return nil;
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
    NSInteger mdxBodyStartPos = pos;
    NSInteger mdxBodySize = mdxt.length - mdxBodyStartPos;
    int lzxlen = lzx042check(&mdxptr[mdxBodyStartPos]);
    NSData *mdxr = [mdxt subdataWithRange:NSMakeRange(mdxBodyStartPos,mdxBodySize)];
    if(lzxlen > 0){
        if(mdx_lzxbuf) free(mdx_lzxbuf);
        mdx_lzxbuf = malloc(lzxlen);
        unsigned int retval = lzx042decode(mdx_lzxbuf, lzxlen, &mdxptr[mdxBodyStartPos], (unsigned int)mdxBodySize);
//        NSLog(@"MDX-LZX file decoder returned %ud, when lzxlen = %d",retval,lzxlen);
        if(retval==0) return nil;
        mdxr = [NSData dataWithBytes:mdx_lzxbuf length:lzxlen];
    }else{
        mdxr = [mdxt subdataWithRange:NSMakeRange(mdxBodyStartPos,mdxBodySize)];
    }
    
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
            pdxt = [NSData dataWithContentsOfFile:[mdxPath stringByAppendingPathComponent:f]];
            if(!pdxt) pdxt = [NSData dataWithContentsOfFile:[mdxPath stringByAppendingPathComponent:f.lowercaseString]];
            if(!pdxt) pdxt = [NSData dataWithContentsOfFile:[mdxPath stringByAppendingPathComponent:f.uppercaseString]];
            if(!pdxt) pdxt = [NSData dataWithContentsOfFile:[mdxPath stringByAppendingPathComponent:[f stringByReplacingOccurrencesOfString:@".pdx" withString:@".PDX"]]];
        }
        if(pdxt){
            int pdxlzxlen = lzx042check(pdxt.bytes);
            if(pdxlzxlen > 0){
                if(pdx_lzxbuf) free(pdx_lzxbuf);
                pdx_lzxbuf = malloc(pdxlzxlen);
                int retvalpdx = lzx042decode(pdx_lzxbuf, pdxlzxlen, pdxt.bytes, (unsigned int)pdxt.length);
//                NSLog(@"PDX-LZX file decoder returned %ud, when pdxlzxlen = %d",retvalpdx,pdxlzxlen);
                if(retvalpdx==0) return nil;
                pdxt = [NSData dataWithBytes:pdx_lzxbuf length:pdxlzxlen];
            }
            return @{@"mdx":mdxr, @"pdx":pdxt};
        }
    }
    return @{@"mdx":mdxr};
}

-(void)prepareMXDRV:(NSData*)mdxt pdx:(NSData*)pdxt
{
    if(!mdxt) return;
    
    MXDRVG_End();
    MXDRVG_Start((int)_samplingRate, 0, 64*1024, 1024*1024);
    MXDRVG_TotalVolume((int)(volume * 256));
    
    // 闇血対策 mxdrv200bではエラーとしていたのでskip
    // だがしかしOPはPCM入ってたからこれじゃダメだよな・・・・
    // LZX圧縮って、、展開PullRequest求ム！
    //    if(pdxt && pdxt.length >= 8 && !memcmp((unsigned char*)pdxt.bytes + 4,"LZX ",4)) pdxt = nil;
    
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
    // 名称などは適当にskip
    
    mdx = [NSMutableData dataWithBytes:mdxData length:10];
    [mdx appendData:mdxt];
    
    if (pdxt)
    {
        pdx = [NSMutableData dataWithBytes:pdxData length:10];
        [pdx appendData:pdxt];
        MXDRVG_SetData((char*)mdx.bytes, (unsigned int)mdx.length, (char*)pdx.bytes, (unsigned int)pdx.length);
    }
    else
    {
        MXDRVG_SetData((char*)mdx.bytes, (unsigned int)mdx.length, NULL, 0);
    }
    
}

-(void)cleanUpAudioQueue
{
    AudioQueueReset(audioQueue);
    first = YES;
}

-(BOOL)playOneFile:(NSString*)file
{
    if(first) AudioQueueStop(audioQueue, YES);
    
    while(pthread_mutex_trylock(&mxdrv_mutex)!=0){
        //        NSLog(@"mutex lock failed in playOneFile");
        [NSThread sleepForTimeInterval:0.001];
    }
    _paused = NO;
    playend = YES;
    playduration = 0;
    oldsec = -1;
    
    NSDictionary *r = [self loadMDXPDX:file];
    if(r == nil) return NO;
    NSData *mdxt = [r objectForKey:@"mdx"];
    NSData *pdxt = [r objectForKey:@"pdx"];
    [self prepareMXDRV:mdxt pdx:pdxt];
    
    _file = file;
    
    NSInteger lc = _loopCount;
    if(lc < 1 || lc > 100) lc = 1;
    
    
    playduration = MXDRVG_MeasurePlayTime((int)lc, 0) + FOCOUNT;    // nofadeout + 8sec
    _duration = playduration / 1000;
    MXDRVG_PlayAt(0, (int)lc, 1);
    
    // MXDRVG_CALLBACK_OPMINT = MXDRVG_MeasurePlayTime_OPMINT;
    //playatではこっちが外され、、ここからではとどかないので概算でいくです
    // ホントはgetworkでポインタ持ってcallbackを指定しOPMINITもどきで計算すべきです
    
    
    if(first)
    {
        first = NO;
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
    
    pthread_mutex_unlock(&mxdrv_mutex);
    AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
    AudioQueueStart(audioQueue, NULL);
    playend = NO; // sinn246:再生直前にplayendをNOにしないと、この前に再生が入ってエラーになる
    [_delegate didStart];
    [_delegate didChangePauseTo:NO];
    return YES;
}


-(float)volume
{
    return volume; // MXDRVG_GetTotalVolume() / 255.0;
}

-(void)setVolume:(float)ivolume
{
    volume = ivolume;
    MXDRVG_TotalVolume((int)(volume * 256));
}

-(BOOL)playFile:(NSString*)file
{
    files = nil;
    [self cleanUpAudioQueue];
    return  [self playOneFile:file];
}

-(BOOL)playFiles:(NSArray *)ifiles index:(NSInteger)index
{
    if(ifiles.count == 0) { return false; }
    [self cleanUpAudioQueue];
    BOOL r = [self playOneFile:[ifiles objectAtIndex:index]];
    if(!r) return r;
    
    files = ifiles;
    fileIndex = index;
    return r;
}

-(void)goNext
{
    if (files.count == 0) return;
    fileIndex = (fileIndex + 1) % files.count;
    [self cleanUpAudioQueue];
    [self playOneFile:files[fileIndex]];
}

-(void)goPrev
{
    if (files.count == 0) return;
    fileIndex = (fileIndex + files.count - 1) % files.count;
    [self cleanUpAudioQueue];
    [self playOneFile:files[fileIndex]];
}


#pragma mark reference interface


-(NSInteger)current
{
    return (NSInteger)(MXDRVG_GetPlayAt() / 1000);
}


#pragma mark action interface
-(void) pause:(BOOL) p
{
    if(p){
        [self doPause];
    }else{
        [self doPlay];
    }
}
-(void) doPause
{
    AudioQueuePause(audioQueue);
    _paused = YES;
    [_delegate didChangePauseTo:_paused];
}

-(void) doPlay
{
    AudioQueueStart(audioQueue, NULL);
    _paused = NO;
    [_delegate didChangePauseTo:_paused];
}

-(void)togglePause
{
    if(!_paused){
        AudioQueuePause(audioQueue);
        _paused = YES;
    }else{
        AudioQueueStart(audioQueue, NULL);
        _paused = NO;
    }
    [_delegate didChangePauseTo:_paused];
}


@end

