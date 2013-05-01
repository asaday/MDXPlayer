//
//  ViewController.h
//  mdxplayer
//
//  Created by asada on 2013/04/03.
//  Copyright (c) 2013 asada. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerVC : UIViewController
-(void)playFile:(NSString*)file path:(NSString*)path;

@property (weak, nonatomic) IBOutlet UILabel *lbl;
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnNext;
@property (weak, nonatomic) IBOutlet UIButton *btnPrev;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *lblTime;
@property (weak, nonatomic) IBOutlet UIView *viewPanel;
@property (weak, nonatomic) IBOutlet UILabel *lblLoop;
@property (weak, nonatomic) IBOutlet UIStepper *stepperLoop;

- (IBAction)tapPlay:(id)sender;
- (IBAction)tapPrev:(id)sender;
- (IBAction)tapNext:(id)sender;
- (IBAction)sliderChanged:(id)sender;
- (IBAction)tapFlip:(id)sender;
- (IBAction)tapLoop:(id)sender;

@end
