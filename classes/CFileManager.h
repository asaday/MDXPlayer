//
//  CFileManager.h
//  CFileManager
//
//  Created by asada on 2013/04/06.
//  Copyright (c) 2013 asada. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *cfmFolderResouecs;
extern NSString *cfmFolderDocuments;
extern NSString *cfmFolderDropbox;

extern NSString *cfmNotifyReload;

@interface CFileInfo : NSObject
@property (nonatomic) BOOL isFolder;
@property (nonatomic) NSString *path;
@property (nonatomic) NSString *title;
@property (nonatomic) long long size;
@property (nonatomic) NSDate *modified;
@end


@interface CFileMnager : NSObject
+(dispatch_queue_t)cfque;
+(void)listOfFolder:(NSString*)path completion:(void(^)(NSArray *lists))completion; // return CFileInfo
+(void)dataOfFile:(NSString*)path completion:(void(^)(NSData *data))completion;

// use in not main thread
+(NSArray*)listOfFolder:(NSString*)path;
+(NSData*)dataOfFile:(NSString*)path;
@end

