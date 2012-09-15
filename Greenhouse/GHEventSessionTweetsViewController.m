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
//  GHEventSessionTweetsViewController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 9/13/10.
//

#import "GHEventSessionTweetsViewController.h"
#import "GHEventSessionTweetViewController.h"
#import "GHEventController.h"
#import "GHEventSessionController.h"

@interface GHEventSessionTweetsViewController()

@property (nonatomic, strong) EventSession *currentSession;

@end

@implementation GHEventSessionTweetsViewController

@synthesize event;
@synthesize session;

- (void)showTwitterForm
{
    self.tweetViewController.tweetText = [[NSString alloc] initWithFormat:@"%@ %@", event.hashtag, session.hashtag];
    [super showTwitterForm];
}

- (void)fetchTweetsWithPage:(NSUInteger)page
{
	[[GHTwitterController sharedInstance] sendRequestForTweetsWithEventId:event.eventId
                                                            sessionNumber:session.number
                                                                     page:page
                                                                 delegate:self];
}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad
{
	self.lastRefreshKey = @"EventSessionTweetsViewController_LastRefresh";
	
	[super viewDidLoad];
    
    self.tweetViewController = [[GHEventSessionTweetViewController alloc] initWithNibName:@"GHTweetViewController" bundle:nil];
//	self.tweetDetailsViewController = [[GHEventSessionTweetDetailsViewController alloc] initWithNibName:@"GHTweetDetailsViewController" bundle:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DLog(@"");
    
    self.event = [[GHEventController sharedInstance] fetchSelectedEvent];
    self.session = [[GHEventSessionController sharedInstance] fetchSelectedSession];
    [[GHTwitterController sharedInstance] fetchTweetsWithEventId:event.eventId
                                                   sessionNumber:session.number
                                                        delegate:self];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	
	self.event = nil;
	self.session = nil;
}

@end
