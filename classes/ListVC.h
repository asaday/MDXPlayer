//
//  ListVC.h
//  mdxplayer
//
//  Created by asada on 2013/04/04.
//  Copyright (c) 2013 asada. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ListVC : UITableViewController
@property (nonatomic) NSString *path;
- (IBAction)tapPlayer:(id)sender;
@end
