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
//  GHEventSessionsFavoritesViewController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 8/2/10.
//

#import "GHEventSessionsFavoritesViewController.h"
#import "GHEventSessionController.h"


@interface GHEventSessionsFavoritesViewController ()

@property (nonatomic, strong) GHEventSessionController *eventSessionController;

@end


@implementation GHEventSessionsFavoritesViewController

@synthesize eventSessionController;


#pragma mark -
#pragma mark EventSessionControllerDelegate methods

- (void)fetchFavoriteSessionsDidFinishWithResults:(NSArray *)sessions
{
    self.arraySessions = sessions;
	[self.tableView reloadData];
	[self dataSourceDidFinishLoadingNewData];
}

- (void)fetchFavoriteSessionsDidFailWithError:(NSError *)error
{
	NSArray *emptyarray = [[NSArray alloc] init];
    self.arraySessions = emptyarray;
	[self.tableView reloadData];
	[self dataSourceDidFinishLoadingNewData];
}

#pragma mark -
#pragma mark PullRefreshTableViewController methods

//- (BOOL)shouldReloadData
//{
//	return (!self.arraySessions || self.lastRefreshExpired || [GHEventSessionController shouldRefreshFavorites]);
//}

//- (void)reloadTableViewDataSource
//{
//	[eventSessionController fetchFavoriteSessionsWithEventId:self.event.eventId delegate:self];
//}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad 
{
	self.lastRefreshKey = @"EventSessionFavoritesViewController_LastRefresh";
	
    [super viewDidLoad];
	
	self.title = @"My Favorites";
    self.eventSessionController = [[GHEventSessionController alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
   	[eventSessionController fetchFavoriteSessionsWithEventId:self.event.eventId delegate:self];
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
	
	self.eventSessionController = nil;
}

@end
