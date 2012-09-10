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
//  GHEventsMainViewController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 7/8/10.
//

#import "GHEventsMainViewController.h"
#import "Event.h"

@interface GHEventsMainViewController()

@property (nonatomic, strong) NSArray *arrayEvents;
@property (nonatomic, strong) GHEventController *eventController;

- (void)completeFetchEvents:(NSArray *)events;

@end

@implementation GHEventsMainViewController

@synthesize arrayEvents;
@synthesize eventController;
@synthesize barButtonRefresh;
@synthesize eventDetailsViewController;


#pragma mark -
#pragma mark Private methods

- (void)completeFetchEvents:(NSArray *)events
{
	self.arrayEvents = events;
	[self.tableView reloadData];
	[self dataSourceDidFinishLoadingNewData];
}


#pragma mark -
#pragma mark EventControllerDelegate methods

- (void)fetchEventsDidFinishWithResults:(NSArray *)events
{
	[self completeFetchEvents:events];
}

- (void)fetchEventsDidFailWithError:(NSError *)error
{
	NSArray *array = [[NSArray alloc] init];
	[self completeFetchEvents:array];
}


#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (arrayEvents)
	{
		Event *event = [arrayEvents objectAtIndex:indexPath.row];
        [eventController setSelectedEvent:event];
		[self.navigationController pushViewController:eventDetailsViewController animated:YES];
	}
}


#pragma mark -
#pragma mark UITableViewDataSource methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdent = @"cell";
	static NSString *PlaceholderCellIdentifier = @"PlaceholderCell";
    
    // add a placeholder cell while waiting on table data
    int count = [self.arrayEvents count];
	
	if (count == 0 && indexPath.row == 0)
	{
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PlaceholderCellIdentifier];
		
        if (cell == nil)
		{
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:PlaceholderCellIdentifier];
            cell.detailTextLabel.textAlignment = UITextAlignmentCenter;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
		
		cell.detailTextLabel.text = @"Loading Events…";
		
		return cell;
    }	
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdent];
	
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdent];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	Event *event = (Event *)[arrayEvents objectAtIndex:indexPath.row];
	
	[cell.textLabel setText:event.title];
	[cell.detailTextLabel setText:event.groupName];
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (arrayEvents)
	{
		return [arrayEvents count];
	}
	else 
	{
		return 1;
	}
}


#pragma mark -
#pragma mark PullRefreshTableViewController methods

- (void)reloadTableViewDataSource
{
    [eventController sendRequestForEventsWithDelegate:self];
}

//- (BOOL)shouldReloadData
//{
//	return (!arrayEvents || self.lastRefreshExpired || [arrayEvents count] == 0);
//}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad 
{
	self.lastRefreshKey = @"EventsMainViewController_LastRefresh";
    DLog(@"");
	[super viewDidLoad];
	
	self.title = @"Upcoming Events";

    self.eventController = [[GHEventController alloc] init];
	self.eventDetailsViewController = [[GHEventDetailsViewController alloc] initWithNibName:nil bundle:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DLog(@"");
	[eventController fetchEventsWithDelegate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    DLog(@"");
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    DLog(@"");
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    DLog(@"");
}

- (void)viewDidUnload 
{	
	[super viewDidUnload];
	
	self.arrayEvents = nil;
	self.eventController = nil;
	self.barButtonRefresh = nil;
	self.eventDetailsViewController = nil;
}

@end
