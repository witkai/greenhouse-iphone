//
//  Copyright 2012 the original author or authors.
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
//  GHEventTweetDetailsViewController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 9/11/12.
//

#import "GHEventTweetDetailsViewController.h"
#import "GHEventTweetViewController.h"
#import "Event.h"
#import "GHEventController.h"

@interface GHEventTweetDetailsViewController ()

@property (nonatomic, strong) Event *event;

@end

@implementation GHEventTweetDetailsViewController


#pragma mark -
#pragma mark GHEventTweetDetailsViewController methods

- (IBAction)actionRetweet:(id)sender
{
//	[[GHTwitterController sharedInstance] postRetweet:tweet.tweetId withURL:retweetUrl delegate:self];
}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tweetViewController = [[GHEventTweetViewController alloc] initWithNibName:@"GHTweetViewController" bundle:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.event = [[GHEventController sharedInstance] fetchSelectedEvent];
}

@end
