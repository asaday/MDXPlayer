//
//  AppDelegate.h
//  mdxplayer
//
//  Created by asada on 2013/04/03.
//  Copyright (c) 2013 asada. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PlayerVC.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) PlayerVC *playerVC;
@end

extern NSString *kNotifyNetOn;
extern NSString *kNotifyNetOff;