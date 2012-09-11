//
//  Copyright 2010-2012 the original author or authors.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//
//  GHEventTweetsViewController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 9/12/10.
//

#import "GHEventTweetsViewController.h"
#import "GHEventController.h"
#import "Event.h"

@interface GHEventTweetsViewController ()

@property (nonatomic, strong) Event *event;

@end

@implementation GHEventTweetsViewController

@synthesize event;

//#pragma mark -
//#pragma mark PullRefreshTableViewController methods
//
//- (void)refreshView
//{
//	NSString *urlString = [[NSString alloc] initWithFormat:EVENT_TWEETS_URL, event.eventId];
//	NSURL *url = [[NSURL alloc] initWithString:urlString];
//	self.tweetUrl = url;
//	self.tweetViewController.tweetUrl = url;
//	self.tweetViewController.tweetText = event.hashtag;
//    
//	urlString = [[NSString alloc]  initWithFormat:EVENT_RETWEET_URL, event.eventId];
//	url = [[NSURL alloc] initWithString:urlString];
//	self.retweetUrl = url;
//	
//	if (![currentEvent.eventId isEqualToNumber:event.eventId])
//	{
//		self.isLoading = YES;
//		[self.arrayTweets removeAllObjects];
//		[self.tableView reloadData];
//	}
//	
//	self.currentEvent = event;
//}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad
{
	self.lastRefreshKey = @"EventTweetsViewController_LastRefresh";
	
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DLog(@"");
    self.event = [[GHEventController sharedInstance] fetchSelectedEvent];
    
    NSString *urlString = [[NSString alloc] initWithFormat:EVENT_TWEETS_URL, event.eventId];
	NSURL *url = [[NSURL alloc] initWithString:urlString];
	self.tweetUrl = url;
	self.tweetViewController.tweetUrl = url;
	self.tweetViewController.tweetText = event.hashtag;
    
	urlString = [[NSString alloc]  initWithFormat:EVENT_RETWEET_URL, event.eventId];
	url = [[NSURL alloc] initWithString:urlString];
	self.retweetUrl = url;
	
	self.isLoading = YES;
	[self.arrayTweets removeAllObjects];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    DLog(@"");
    [self reloadData];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.event = nil;
}

@end
