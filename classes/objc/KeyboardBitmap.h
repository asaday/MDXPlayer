//
//  KeyboardBitmap.h
//  mdxplayer
//
//  Created by sinn246 on 2016/05/05.
//  Copyright © 2016年 asada. All rights reserved.
//

#ifndef KeyboardBitmap_h
#define KeyboardBitmap_h

#import <UIKit/UIKit.h>
#define KEYB_HEIGHT 17

#define BS_X (4*7*8)
#define BS_Y (KEYB_HEIGHT*8)

CGImageRef makeKeyboardBitmap(BOOL doPaint);

#endif /* KeyboardBitmap_h */
