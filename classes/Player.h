//
//  Player.h
//  mdxplayer
//
//  Created by asada on 2013/04/03.
//  Copyright (c) 2013 asada. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Player : NSObject
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *file;
@property (nonatomic) int duration;
@property (nonatomic) int current;
@property (nonatomic) BOOL paused;
@property (nonatomic) float volume;
@property (nonatomic) int loopcount;
@property (nonatomic) BOOL speedup;

-(void)playFile:(NSString*)file;
-(void)playFiles:(NSArray*)files start:(int)index;
-(void)pause:(BOOL)p;
-(void)seekNext;
-(void)seekPrev;
-(void)seekIndex:(int)index;

+(NSString*)titleForMDXFile:(NSString*)file;
+(NSString*)titleForMDXData:(NSData*)mdxt;

-(NSArray*)files;
-(int)nowIndex;

@end

