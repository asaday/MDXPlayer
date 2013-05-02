//
//  ListVC.m
//  mdxplayer
//
//  Created by asada on 2013/04/04.
//  Copyright (c) 2013 asada. All rights reserved.
//

#import "AppDelegate.h"
#import "ListVC.h"
#import "Player.h"
#import "CFileManager.h"
#import "InfoVC.h"

#import <Dropbox/Dropbox.h>




@interface ListVC ()

@end

@implementation ListVC
{
    NSMutableArray *files;
    NSMutableArray *folders;
    UIBarButtonItem *rbb;
    NSMutableDictionary *file2title;
}

-(void)dealloc
{
	[NCenter removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.backgroundColor = [UIColor lightGrayColor];
	
	UIBarButtonItem *bb = [[UIBarButtonItem alloc] init];
	bb.tintColor = [UIColor colorWithWhite:0.9 alpha:1];// colorWithWhite:0.8 alpha:1];
	[bb setTitleTextAttributes:@{UITextAttributeTextColor:[UIColor darkGrayColor],UITextAttributeTextShadowColor:[UIColor clearColor]} forState:UIControlStateNormal];
	self.navigationItem.backBarButtonItem = bb;
	
	[self.navigationItem.rightBarButtonItem setTitleTextAttributes:@{UITextAttributeFont:[UIFont boldSystemFontOfSize:17]} forState:UIControlStateNormal];

    rbb = self.navigationItem.rightBarButtonItem;
	
    if(!_path)	// root
    {
        self.title = @"MDX";
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [btn addTarget:self action:@selector(tapInfo:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *bbb = [[UIBarButtonItem alloc] initWithCustomView:btn];
        self.navigationItem.leftBarButtonItem = bbb;
        
    }

	if([_path isEqualToString:cfmFolderDropbox])
	{
		[self redispDropboxRB];
		[NCenter addObserver:self selector:@selector(reload) name:cfmNotifyReload object:nil];
		[NCenter addObserver:self selector:@selector(dropbox_logined) name:@"DROPBOX_LOGINED" object:nil];
	}
	
    file2title = [NSMutableDictionary dictionary];
    [self reload];
}

#pragma mark Dropbox assists

-(void)redispDropboxRB
{
    
    UIBarButtonItem *sbb;
    if([DBAccountManager sharedManager].linkedAccount)
        sbb = [[UIBarButtonItem alloc] initWithTitle:@"logout" style:UIBarButtonItemStyleBordered target:self action:@selector(dropbox_logout)];
    else
        sbb = [[UIBarButtonItem alloc] initWithTitle:@"login" style:UIBarButtonItemStyleBordered target:self action:@selector(dropbox_login)];

    sbb.tintColor = [UIColor colorWithWhite:0.9 alpha:1];
    [sbb setTitleTextAttributes:@{UITextAttributeTextColor:[UIColor darkGrayColor],UITextAttributeTextShadowColor:[UIColor clearColor]} forState:UIControlStateNormal];

    self.navigationItem.rightBarButtonItems = @[rbb,sbb];
}

-(void)dropbox_login
{
    [[DBAccountManager sharedManager] linkFromController:self];
}

-(void)dropbox_logout
{
    [[DBAccountManager sharedManager].linkedAccount unlink];
    folders = nil;
    files = nil;
    [self.tableView reloadData];
}

-(void)dropbox_logined
{
	[self redispDropboxRB];
	[self reload];
}

#pragma mark rutines

-(void)reload
{
    [CFileMnager listOfFolder:_path completion:^(NSArray *lists) {
		
		
		if(!lists || !lists.count)
		{
			if([_path isEqualToString:cfmFolderDropbox])
				[self showMessage:@"Copy files to Dropbox /Apps/mdx or /アプリ/mdx"];
			
			if([_path isEqualToString:cfmFolderDocuments])
				[self showMessage:@"Copy files with iTunes app from PC/mac/X68k"];
			
			return;
		}
		
        files = [NSMutableArray array];
        folders = [NSMutableArray array];

        for(CFileInfo *info in lists)
        {
            if(info.isFolder)
            {
                [folders addObject:info];
                continue;
            }
            
            if(![info.title.lowercaseString hasSuffix:@".mdx"]) continue;
            [files addObject:info];
        }
        [self.tableView reloadData];
    }];
    
}

-(PlayerVC*)getPlayerVC
{
    AppDelegate *gate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    return gate.playerVC;
}

#pragma mark actions

-(void)tapInfo:(id)sender
{
	InfoVC *vc = [[InfoVC alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    
}

- (IBAction)tapPlayer:(id)sender
{
    PlayerVC *vc = [self getPlayerVC];
    [self.navigationController pushViewController:vc animated:YES];
    
}

-(void)showMessage:(NSString*)msg
{
	[[[UIAlertView alloc] initWithTitle:nil message:msg
							   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
}


#pragma mark table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(!section) return folders.count;
    return files.count;
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
		
		
		cell.backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"tblbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(4, 0, 4, 0) ]];
		cell.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
		
		cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.detailTextLabel.backgroundColor = [UIColor clearColor];
		cell.textLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1];
		cell.textLabel.shadowColor = [UIColor colorWithWhite:1 alpha:1];
		cell.textLabel.shadowOffset = CGSizeMake(.5, .5);
		
		cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }

    if(!indexPath.section)
    {
        CFileInfo *info = [folders objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
        cell.textLabel.text = info.title;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.text = nil;
    }
    else
    {
        CFileInfo *info = [files objectAtIndex:indexPath.row];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:14];
        cell.detailTextLabel.text = info.title;
        cell.accessoryType = UITableViewCellAccessoryNone;

        NSString *title = [file2title objectForKey:info.path];
        if(title)
            cell.textLabel.text = title;
        else
        {
			// ここがあるからreuseダメかもね
            __weak UITableViewCell *wc = cell;
            [CFileMnager dataOfFile:info.path completion:^(NSData *data) {
                NSString *title = [Player titleForMDXData:data];
                wc.textLabel.text = title;
                [file2title setValue:title forKey:info.path];
                [wc setNeedsLayout];
            }];
        }
    }
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section ? 64 : 44;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!indexPath.section)
    {
        ListVC *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"list"];
        CFileInfo *info = [folders objectAtIndex:indexPath.row];
        vc.path = info.path;
        vc.title = info.title;
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    
    PlayerVC *vc = [self getPlayerVC];
    
    CFileInfo *info = [files objectAtIndex:indexPath.row];
    [vc playFile:info.path path:_path];
    
    [self.navigationController pushViewController:vc animated:YES];
    
    
}

@end
