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
//  GHPullRefreshTableViewController.h
//  Greenhouse
//
//  Created by Roy Clarkson on 8/27/10.
//

#import <UIKit/UIKit.h>
#import "GHBaseViewController.h"

@interface GHPullRefreshTableViewController : GHBaseViewController <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (assign, getter=isReloading) BOOL reloading;
@property (nonatomic, copy) NSString *lastRefreshKey;
@property (nonatomic, strong) NSDate *lastRefreshDate;
@property (nonatomic, assign, readonly) BOOL lastRefreshExpired;

- (void)reloadData;
- (BOOL)shouldReloadData;
- (void)reloadTableViewDataSource;
- (void)dataSourceDidFinishLoadingNewData;

@end