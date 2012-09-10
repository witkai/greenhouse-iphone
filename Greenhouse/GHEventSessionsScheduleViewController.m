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
//  GHEventSessionsScheduleViewController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 9/10/12.
//

#import "GHEventSessionsScheduleViewController.h"
#import "Event.h"
#import "GHEventController.h"
#import "GHDateHelper.h"
#import "GHEventSessionsByDayViewController.h"

@interface GHEventSessionsScheduleViewController ()

@property (nonatomic, strong) Event *event;
@property (nonatomic, strong) NSArray *eventDates;
@property (nonatomic, strong) NSMutableDictionary *viewControllers;

@end

@implementation GHEventSessionsScheduleViewController

@synthesize event;
@synthesize eventDates;
@synthesize viewControllers;
@synthesize tableViewMenu;
@synthesize sessionsByDayViewController;


#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *date = [eventDates objectAtIndex:indexPath.row];
    GHEventSessionsByDayViewController *vc = [viewControllers objectForKey:[date description]];
    if (vc == nil)
    {
        vc = [[GHEventSessionsByDayViewController alloc] initWithNibName:@"GHEventSessionsViewController" bundle:nil];
        [viewControllers setObject:vc forKey:[date description]];
    }
    vc.eventDate = date;
    [self.navigationController pushViewController:vc animated:YES];
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}


#pragma mark -
#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdent = @"menuCell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdent];	
	if (cell == nil)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
    NSDate *eventDate = [eventDates objectAtIndex:indexPath.row];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"EEEE, MMMM d"];
    NSString *title = [dateFormatter stringFromDate:eventDate];
	[cell.textLabel setText:title];
	
	return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return eventDates.count;
}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"Schedule";
	self.eventDates = [[NSMutableArray alloc] init];
	self.viewControllers = [[NSMutableDictionary alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DLog(@"");
    self.event = [[GHEventController sharedInstance] fetchSelectedEvent];
	[viewControllers removeAllObjects];
	self.eventDates = [GHDateHelper daysBetweenStartTime:event.startTime endTime:event.endTime];
	[tableViewMenu reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
	self.eventDates = nil;
	self.viewControllers = nil;
	self.event = nil;
	self.tableViewMenu = nil;
}


@end
