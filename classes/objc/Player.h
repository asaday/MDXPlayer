//
//  Player.h
//  mdxplayer
//
//  Created by asada on 2013/04/03.
//  Copyright (c) 2013 asada. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol PlayerDelegate <NSObject>
-(void)didStart;
-(void)didEnd;
-(void)didChangeSecond;
-(void)didChangeStatus;
-(void)didChangePauseTo:(BOOL) pause;
@end

@interface Player : NSObject

+ (nonnull Player*)sharedInstance;

@property (nonatomic,weak,nullable) id <PlayerDelegate> delegate;
@property (nonatomic,nullable) NSString *title;
@property (nonatomic,nullable) NSString *file;
@property (nonatomic) NSInteger duration;
@property (nonatomic) NSInteger current;
@property (nonatomic) BOOL paused;
@property (nonatomic) float volume;
@property (nonatomic) NSInteger loopCount;
@property (nonatomic) NSInteger samplingRate;
@property (nonatomic) BOOL speedup;

-(BOOL)playFile:(nonnull NSString*)file;
-(BOOL)playFiles:(nonnull NSArray*)files index:(NSInteger)index;

-(MPRemoteCommandHandlerStatus)goNext;
-(MPRemoteCommandHandlerStatus)goPrev;

-(MPRemoteCommandHandlerStatus)togglePause;

+(nullable NSString*)titleForMDXFile:(nonnull NSString*)file;
+(void)prepareMask:(nonnull CALayer*)maskLayer;
+(void)redrawKey:(nonnull CALayer*)keyLayer speana:(nonnull CALayer*)speanaLayer paint:(BOOL)paint;

@end

