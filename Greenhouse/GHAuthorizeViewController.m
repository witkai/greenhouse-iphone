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
//  GHAuthorizeViewController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 6/7/10.
//

#import "GHAuthorizeViewController.h"
#import "GHSignInViewController.h"
#import "GHJoinNowViewController.h"

@implementation GHAuthorizeViewController

@synthesize signInViewController;
@synthesize joinNowViewController;


- (IBAction)actionSignIn:(id)sender
{
    [self.navigationController pushViewController:signInViewController animated:YES];
}

- (IBAction)actionJoinNow:(id)sender
{
    [self.navigationController pushViewController:joinNowViewController animated:YES];
}


#pragma mark -
#pragma mark UIViewController methods

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:nil action:nil];
    [self.navigationItem setBackBarButtonItem:backButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
    
    self.signInViewController = nil;
    self.joinNowViewController = nil;
}

@end
