//
//  InfoVC.m
//  mdxplayer
//
//  Created by asada on 2013/04/18.
//  Copyright (c) 2013 asada. All rights reserved.
//

#import "InfoVC.h"

@interface InfoVC () <UIWebViewDelegate>
@end

@implementation InfoVC

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"information";
	UIWebView *wview = [[UIWebView alloc] initWithFrame:self.view.bounds];
	[self.view addSubview:wview];
    wview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	wview.delegate = self;
    [wview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://nagisaworks.com/mdxplayer/info"]]];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if([request.URL.host hasSuffix:@"nagisaworks.com"]) return YES;

	[[UIApplication sharedApplication] openURL:request.URL];
	return NO;
}

@end
