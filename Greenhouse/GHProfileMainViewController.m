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
//  GHProfileMainViewController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 6/7/10.
//

#import "GHProfileMainViewController.h"
//#import "GHProfile.h"
#import "GHCoreDataManager.h"

@interface GHProfileMainViewController()

@property (nonatomic, strong) GHProfileController *profileController;

@end

@implementation GHProfileMainViewController

@synthesize profileController;
@synthesize labelDisplayName;
@synthesize imageViewPicture;
@synthesize activityIndicatorView;


#pragma mark -
#pragma mark Public methods

- (IBAction)actionSignOut:(id)sender
{
    [GHOAuth2Controller deleteAccessGrant];
    [[GHCoreDataManager sharedInstance] deletePersistentStore];
	[appDelegate showAuthorizeNavigationViewController];
}

- (IBAction)actionRefresh:(id)sender
{
    [profileController sendRequestForProfileWithDelegate:self];
}


#pragma mark -
#pragma mark ProfileControllerDelegate methods

- (void)fetchProfileDidFinishWithResults:(Profile *)profile;
{
//	[activityIndicatorView stopAnimating];
	labelDisplayName.text = profile.displayName;
	imageViewPicture.imageUrl = [NSURL URLWithString:profile.imageUrl];
	[imageViewPicture startImageDownload];
}

- (void)fetchProfileDidFailWithError:(NSError *)error
{
//	[activityIndicatorView stopAnimating];
}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad 
{
    [super viewDidLoad];
    DLog(@"");
    self.profileController = [[GHProfileController alloc] init];
	activityIndicatorView.hidesWhenStopped = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    DLog(@"");
    [profileController fetchProfileWithDelegate:self];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    DLog(@"");
	self.profileController = nil;
	self.labelDisplayName = nil;
	self.imageViewPicture = nil;
	self.activityIndicatorView = nil;
}

@end
