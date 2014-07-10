//
//  CFileManager.m
//  CFileManager
//
//  Created by asada on 2013/04/06.
//  Copyright (c) 2013 asada. All rights reserved.
//
#import "AppDelegate.h"
#import "CFileManager.h"
#import <Dropbox/Dropbox.h>

#include "keys.h"
/*
keys.h
 #define DROPBOX_KEY	@"..."
 #define DROPBOX_SECRET @"..."
 
 */




NSString *cfmFolderResouecs = @"__resources__";
NSString *cfmFolderDocuments = @"__documents__";
NSString *cfmFolderDropbox = @"__dropbox__";

NSString *cfmNotifyReload = @"CFM_RELOADREQ";



@implementation CFileInfo
-(NSString*)description
{
    return [NSString stringWithFormat:@"%@ folder:%d size:%lld",_path,_isFolder,_size];
}
@end

@interface CFileMnager ()
@property (nonatomic) NSString *resoucePath;
@property (nonatomic) NSString *documentsPath;

@end

@implementation CFileMnager
{
    dispatch_queue_t cfque;
}

+(CFileMnager*)shared
{
    static CFileMnager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[CFileMnager alloc] init];
    });
    return shared;
}


-(id)init
{
    self = [super init];
    _resoucePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"buildin"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    _documentsPath = [paths objectAtIndex:0];

    DBAccountManager *dbmanager = [[DBAccountManager alloc] initWithAppKey:DROPBOX_KEY secret:DROPBOX_SECRET];
    [DBAccountManager setSharedManager:dbmanager];

    [dbmanager addObserver:self block:^(DBAccount *account) {
        if(account.linked)
        {
            DBFilesystem *dbfilesystem = [[DBFilesystem alloc] initWithAccount:account];
            [DBFilesystem setSharedFilesystem:dbfilesystem];
            [dbfilesystem addObserver:self forPathAndDescendants:[DBPath root] block:^{
                [NCenter postNotificationName:cfmNotifyReload object:nil];
            }];
        }
        else [DBFilesystem setSharedFilesystem:nil];
        
    }];
    
    DBFilesystem *dbfilesystem = [[DBFilesystem alloc] initWithAccount:dbmanager.linkedAccount];
    [DBFilesystem setSharedFilesystem:dbfilesystem];
    [dbfilesystem addObserver:self forPathAndDescendants:[DBPath root] block:^{
        [NCenter postNotificationName:cfmNotifyReload object:nil];
    }];

    // dropboxはbackgroundのうえにthredsafeではないようなので指定キューで処理
    cfque = dispatch_queue_create("com.com.com.cfmanager", NULL);

    return self;
}

-(dispatch_queue_t)cfque
{
    return cfque;
}

+(dispatch_queue_t)cfque
{
    return [[CFileMnager shared] cfque];//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
}

+(NSArray*)listOfRoot
{
    NSMutableArray *ret = [NSMutableArray array];
    
    CFileInfo *info;
    
    info = [[CFileInfo alloc] init];
    info.title = @"Build-in";
    info.path = cfmFolderResouecs;
    info.isFolder = YES;
    [ret addObject:info];
    
    info = [[CFileInfo alloc] init];
    info.title = @"Documents";
    info.path = cfmFolderDocuments;
    info.isFolder = YES;
    [ret addObject:info];
    
    info = [[CFileInfo alloc] init];
    info.title = @"Dropbox";
    info.path = cfmFolderDropbox;
    info.isFolder = YES;
    [ret addObject:info];
    
    return ret;
}

+(NSArray*)listOfLocalFolder:(NSString*)apath vpath:(NSString*)vpath
{
    NSArray *contents = [FileManager contentsOfDirectoryAtPath:apath error:nil];

    NSMutableArray *ret = [NSMutableArray array];
    for(NSString *file in contents)
    {
        BOOL isDir = NO;
        NSString *ap = [apath stringByAppendingPathComponent:file];
        
        [FileManager fileExistsAtPath:ap isDirectory:&isDir];
        NSDictionary *atb = [FileManager attributesOfItemAtPath:ap error:nil];
        CFileInfo *info = [[CFileInfo alloc] init];
        info.path = [vpath stringByAppendingPathComponent:file];
        info.size = [[atb objectForKey:NSFileSize] longLongValue];
        info.isFolder = isDir;
        info.title = file;
        [ret addObject:info];
    }
    
    return ret;
}

+(NSArray*)listOfDropboxFolder:(NSString *)path
{
    DBPath *p = [[DBPath root] childPath:path];
    
    NSArray *ar = [[DBFilesystem sharedFilesystem] listFolder:p error:nil];
    NSMutableArray *ret = [NSMutableArray array];
    for(DBFileInfo *dbi in ar)
    {
        CFileInfo *info = [[CFileInfo alloc] init];
        info.path = [cfmFolderDropbox stringByAppendingPathComponent:dbi.path.stringValue];
        info.title = dbi.path.name;
        info.size = dbi.size;
        info.isFolder = dbi.isFolder;
        [ret addObject:info];
    }
    
    return [ret sortedArrayUsingComparator:^NSComparisonResult(CFileInfo *obj1, CFileInfo *obj2) {
        return [obj1.title compare:obj2.title options:NSNumericSearch | NSCaseInsensitiveSearch];
    }];

}

+(NSArray*)listOfFolder:(NSString*)path
{
    CFileMnager *scfm = [CFileMnager shared];

    if(!path || [path isEqualToString:@"/"])
        return  [CFileMnager listOfRoot];
    
    if([path hasPrefix:cfmFolderResouecs])
    {
        NSString *apath = [scfm.resoucePath stringByAppendingPathComponent:[path substringFromIndex:cfmFolderResouecs.length]];
        return [CFileMnager listOfLocalFolder:apath vpath:path];
    }
    
    if([path hasPrefix:cfmFolderDocuments])
    {
        NSString *apath = [scfm.documentsPath stringByAppendingPathComponent:[path substringFromIndex:cfmFolderDocuments.length]];
        return [CFileMnager listOfLocalFolder:apath vpath:path];
    }
    
    if([path hasPrefix:cfmFolderDropbox])
    {
        NSString *rpath = [path substringFromIndex:cfmFolderDropbox.length];
        return [CFileMnager listOfDropboxFolder:rpath];
    }

    return nil;
}

+(void)listOfFolder:(NSString*)path completion:(void (^)(NSArray *))completion // return CFileInfo
{
    if(!completion) return;
    if(![path hasPrefix:cfmFolderDropbox])
    {
        completion([CFileMnager listOfFolder:path]);
        return;
    }
    
    
    
    [NCenter postNotificationName:kNotifyNetOn object:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^() { // こっちはbackいけるかも
        NSArray *r = [CFileMnager listOfFolder:path];
        dispatch_async(dispatch_get_main_queue(), ^() {
            [NCenter postNotificationName:kNotifyNetOff object:nil];
            completion(r);
        });
    });
}

+(NSData*)dataOfFile:(NSString *)path
{
    CFileMnager *scfm = [CFileMnager shared];
    
    if([path hasPrefix:cfmFolderResouecs])
    {
        NSString *apath = [scfm.resoucePath stringByAppendingPathComponent:[path substringFromIndex:cfmFolderResouecs.length]];
        return [NSData dataWithContentsOfFile:apath];
    }
    
    if([path hasPrefix:cfmFolderDocuments])
    {
        NSString *apath = [scfm.documentsPath stringByAppendingPathComponent:[path substringFromIndex:cfmFolderDocuments.length]];
        return [NSData dataWithContentsOfFile:apath];
    }
    
    if([path hasPrefix:cfmFolderDropbox])
    {
        NSString *rpath = [path substringFromIndex:cfmFolderDropbox.length];
        DBPath *p = [[DBPath root] childPath:rpath];
        DBFile *f = [[DBFilesystem sharedFilesystem] openFile:p error:nil];
        NSData *d = [f readData:nil];
        [f close];
        return d;
        
    }
    return nil;
}

+(void)dataOfFile:(NSString*)path completion:(void (^)(NSData *))completion
{
    if(!completion) return;
    if(![path hasPrefix:cfmFolderDropbox])
    {
        completion([CFileMnager dataOfFile:path]);
        return;
    }
    
    [NCenter postNotificationName:kNotifyNetOn object:nil];
    dispatch_async([CFileMnager cfque], ^() {       // こっちは２あけエラーとかでる
        NSData *r = [CFileMnager dataOfFile:path];
        dispatch_async(dispatch_get_main_queue(), ^() {
            completion(r);
            [NCenter postNotificationName:kNotifyNetOff object:nil];
        });
    });
}



@end


