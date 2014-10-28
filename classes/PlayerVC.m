//
//  ViewController.m
//  mdxplayer
//
//  Created by asada on 2013/04/03.
//  Copyright (c) 2013 asada. All rights reserved.
//

#import "PlayerVC.h"
#import "Player.h"
#import "CFileManager.h"

@interface PlayerVC () <UITableViewDataSource,UITableViewDelegate>

@end

@implementation PlayerVC
{
    Player *player;
	NSString *pathName;
    UITableView *table;
    UIView *panel;
    int flipmode;
    int nowidx;
    BOOL inHide;
	BOOL inBack;
	int loopcnt;
}

-(void)dealloc
{
    [NCenter removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _btnPlay.selected = !player.paused;
    _lbl.layer.cornerRadius = 8;
    _lbl.clipsToBounds = YES;
	
	_lbl.backgroundColor = [UIColor blackColor];
	_lbl.textColor = [UIColor colorWithRed:159/255.0 green:160/255.0 blue:238/255.0 alpha:1];
	
	_lblTime.font = [UIFont fontWithName:@"Digital-7Mono" size:42];
	_lblTime.textColor = [UIColor colorWithRed:159/255.0 green:160/255.0 blue:238/255.0 alpha:1];

	_lblLoop.font = [UIFont fontWithName:@"Digital-7Mono" size:22];
	_lblLoop.textColor = [UIColor colorWithRed:159/255.0 green:160/255.0 blue:238/255.0 alpha:1];
 
	loopcnt = [UserDefaults integerForKey:@"loopcount"];
	if(loopcnt < 1 || loopcnt > 100)
	{
		loopcnt = 1;
		[UserDefaults setInteger:loopcnt forKey:@"loopcount"];
		[UserDefaults synchronize];
	}
	_stepperLoop.value = loopcnt;
	_stepperLoop.tintColor =  [UIColor colorWithRed:159/255.0 green:160/255.0 blue:238/255.0 alpha:0.6];
	
	
	UILongPressGestureRecognizer *ges = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longtap:)];
	[_btnNext addGestureRecognizer:ges];
	
    [NCenter addObserver:self selector:@selector(remote:) name:@"REMOTE" object:nil];
	[NCenter addObserver:self selector:@selector(notifyBack) name:UIApplicationDidEnterBackgroundNotification object:nil];
	[NCenter addObserver:self selector:@selector(notifyFore) name:UIApplicationDidBecomeActiveNotification object:nil];
	
    panel = _viewPanel;

    table = [[UITableView alloc] initWithFrame:panel.frame style:UITableViewStylePlain];
    table.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    table.delegate = self;
    table.dataSource = self;
    table.backgroundColor = [UIColor blackColor];
    table.separatorColor = [UIColor darkGrayColor];
	table.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    table.separatorInset = UIEdgeInsetsZero;
    [self.view addSubview:table];
    [self.view sendSubviewToBack:table];
    
    [self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:17]} forState:UIControlStateNormal];

	
	// mmdspみたく色々表示したいが、、MXDRVのGあたりを拾えばきっと、
	// アドレスの内容は、、20年前のことなので忘れたっす
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	inHide = NO;
	[self performSelector:@selector(redisp) withObject:nil afterDelay:0];

}

-(void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	inHide = YES;
}

#pragma mark Notify

-(void)notifyFore
{
	inBack = NO;
	[self performSelector:@selector(redisp) withObject:nil afterDelay:0];
}

-(void)notifyBack
{
	inBack = YES;
}
-(BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remote:(NSNotification *)notify
{
    UIEvent *event = notify.object;
    
    if (event.type != UIEventTypeRemoteControl) return;
	
    switch (event.subtype)
    {
        case UIEventSubtypeRemoteControlPlay:
        case UIEventSubtypeRemoteControlPause:
        case UIEventSubtypeRemoteControlStop:
        case UIEventSubtypeRemoteControlTogglePlayPause:
            [self tapPlay:nil];break;
			
        case UIEventSubtypeRemoteControlNextTrack:
            [self tapNext:nil]; break;
			
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self tapPrev:nil]; break;
            
        default: break;
    }
}

#pragma mark Operation

-(void)playFile:(NSString*)file path:(NSString*)path
{
    if(!player) player = [[Player alloc] init];
	player.loopcount = loopcnt;

    pathName = [path lastPathComponent];
	
    [CFileMnager listOfFolder:path completion:^(NSArray *lists) {
        NSMutableArray *files = [NSMutableArray array];
        int start = 0;
        for(CFileInfo *info in lists)
        {
            if(![info.title.lowercaseString hasSuffix:@".mdx"]) continue;
            if(file &&  [file isEqualToString:info.path]) start = files.count;
            [files addObject:info.path];
        }
        
        [player playFiles:files start:start];
        
        _btnPlay.selected = YES;
        [self performSelector:@selector(redisp) withObject:nil afterDelay:0];
        [table reloadData];
        nowidx = start;
        if(files.count)[table selectRowAtIndexPath:[NSIndexPath indexPathForRow:nowidx inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];

    }];
}


-(void)redisp
{
    if(player.paused || inHide|| inBack) return;
	
    int current = player.current / 1000;
    int duration = player.duration / 1000;
    
    NSString *ts = [NSString stringWithFormat:@"%d:%02d / %d:%02d",
                    current/60, current%60, duration/60, duration%60];
    
	_lblTime.text = ts;
    NSString *title = player.title;
    if(!title) title = @"...";
	NSString *filename = player.file.lastPathComponent;

    // あの頃は先頭だけ全角なんて結構みんなやってたから今見るとアレだけど、そのままいっとくね
	_lbl.text = [NSString stringWithFormat:@"%@\n\n%@\n%@", title, filename, pathName];

	if(!filename || !pathName) _lbl.text = @"selct any file or waiting...";
	
	_lblLoop.text = [NSString stringWithFormat:@"Loop %d",loopcnt];
	
    
    int nidx = player.nowIndex;
    if(nowidx != nidx)
    {
        nowidx = nidx;
        if(player.files.count) [table selectRowAtIndexPath:[NSIndexPath indexPathForRow:nowidx inSection:0] animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    }
    
    [self performSelector:@selector(redisp) withObject:nil afterDelay:0.5];
}

#pragma mark Actions

- (IBAction)tapPlay:(id)sender
{
    
    if(_btnPlay.selected)
    {
        _btnPlay.selected = NO;
        [player pause:YES];
    }
    else
    {
        _btnPlay.selected = YES;
        [player pause:NO];
        [self performSelector:@selector(redisp) withObject:nil afterDelay:0.5];
    }
}

- (IBAction)tapPrev:(id)sender
{
    [player seekPrev];
    [self performSelector:@selector(redisp) withObject:nil afterDelay:0.5];
    _btnPlay.selected = YES;
}

- (IBAction)tapNext:(id)sender
{
    [player seekNext];
    [self performSelector:@selector(redisp) withObject:nil afterDelay:0.5];
    _btnPlay.selected = YES;
}

- (IBAction)sliderChanged:(id)sender
{
    player.volume = _slider.value;
}


- (IBAction)tapFlip:(id)sender
{
	[table reloadData];
	if(!flipmode)
	{
		[UIView transitionFromView:panel toView:table duration:0.4 options:UIViewAnimationOptionTransitionFlipFromLeft completion:^(BOOL finished) {
			flipmode = 1;
			if(player.files.count) [table selectRowAtIndexPath:[NSIndexPath indexPathForRow:nowidx inSection:0] animated:NO scrollPosition:UITableViewScrollPositionMiddle];
		}];
	}
	else
	{
		[UIView transitionFromView:table toView:panel duration:0.4 options:UIViewAnimationOptionTransitionFlipFromLeft completion:^(BOOL finished) {
			flipmode = 0;
		}];
		
	}
}

-(void)longtap:(UILongPressGestureRecognizer*)ges
{
	// omake
	if(ges.state == UIGestureRecognizerStateBegan) player.speedup = YES;
	else if(ges.state != UIGestureRecognizerStateChanged) player.speedup = NO;
}


#pragma mark TableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return player.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
        cell.textLabel.minimumScaleFactor = 0.6;
        cell.textLabel.numberOfLines = 2;
		
		cell.backgroundView = [[UIView alloc] init];
        cell.backgroundView.backgroundColor	 = [UIColor blackColor];
		cell.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		
		cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.detailTextLabel.backgroundColor = [UIColor clearColor];
		cell.textLabel.textColor = [UIColor colorWithRed:159/255.0 green:160/255.0 blue:238/255.0 alpha:1];
		
		cell.detailTextLabel.textColor = [UIColor colorWithRed:159/255.0 green:160/255.0 blue:238/255.0 alpha:.8];
        
		cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
		cell.separatorInset = UIEdgeInsetsZero;
		
		cell.selectedBackgroundView = [[UIView alloc] init];
		cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0.20 green:0.25 blue:0.65 alpha:1];
        
        if(NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1)
        {
            cell.layoutMargins = UIEdgeInsetsZero;
            cell.preservesSuperviewLayoutMargins = NO;
        }
    }
    
    NSString *path = [player.files objectAtIndex:indexPath.row];

    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
    cell.detailTextLabel.text = [path lastPathComponent];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
    __weak UITableViewCell *wc = cell;
    [CFileMnager dataOfFile:path completion:^(NSData *data) {
        wc.textLabel.text = [Player titleForMDXData:data];
        [wc setNeedsLayout];
    }];
    
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 64;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [player seekIndex:indexPath.row];
}


- (IBAction)tapLoop:(id)sender
{
	loopcnt = _stepperLoop.value;
	if(loopcnt < 1 || loopcnt > 100) loopcnt = 1;
	[UserDefaults setInteger:loopcnt forKey:@"loopcount"];
	[UserDefaults synchronize];
	
	_lblLoop.text = [NSString stringWithFormat:@"Loop %d",loopcnt];
	player.loopcount = loopcnt;
}

@end
