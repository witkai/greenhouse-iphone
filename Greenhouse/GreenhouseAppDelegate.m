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
//  GreenhouseAppDelegate.m
//  Greenhouse
//
//  Created by Roy Clarkson on 6/7/10.
//

#import <CoreLocation/CoreLocation.h>
#import "GreenhouseAppDelegate.h"
#import "GHAuthorizeNavigationViewController.h"
#import "GHOAuth2Controller.h"

@interface GreenhouseAppDelegate()

- (void)verifyLocationServices;

@end

@implementation GreenhouseAppDelegate

@synthesize window;
@synthesize tabBarController;
@synthesize authorizeNavigationViewController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (void)showAuthorizeNavigationViewController
{	
	[tabBarController.view removeFromSuperview];
    [authorizeNavigationViewController.navigationController popToRootViewControllerAnimated:NO];
	[window addSubview:authorizeNavigationViewController.view];
}

- (void)showTabBarController
{
	[authorizeNavigationViewController.view removeFromSuperview];
	[window addSubview:tabBarController.view];
	tabBarController.selectedIndex = 0;
}

- (void)reloadDataForCurrentView
{
	if ([tabBarController isViewLoaded] && [tabBarController.selectedViewController respondsToSelector:@selector(reloadData)])
	{
		[tabBarController.selectedViewController performSelector:@selector(reloadData)];
	}	
}

- (void)verifyLocationServices
{
	if ([CLLocationManager locationServicesEnabled] == NO) 
	{
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" 
																		message:@"Greenhouse would like to use your current location but you currently have all location services disabled. If you proceed, you will be asked to confirm whether location services should be reenabled." 
																	   delegate:nil 
															  cancelButtonTitle:@"OK" 
															  otherButtonTitles:nil];
        [servicesDisabledAlert show];
    }	
}


#pragma mark -
#pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1)
	{
		// sign out
		[[GHOAuth2Controller sharedInstance] deleteAccessGrant];
		[self showAuthorizeNavigationViewController];
	}
}


#pragma mark -
#pragma mark UITabBarControllerDelegate methods

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
	
}


#pragma mark - 
#pragma mark Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Greenhouse" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[GHAppSettings documentsDirectory] URLByAppendingPathComponent:@"Greenhouse.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


#pragma mark -
#pragma mark UIApplicationDelegate methods

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	DLog(@"");	
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	DLog(@"");
		
	if ([GHUserSettings resetAppOnStart])
	{
		DLog(@"reset app");
		[[GHOAuth2Controller sharedInstance] deleteAccessGrant];
		[GHUserSettings reset];
		[GHUserSettings setAppVersion:[GHAppSettings appVersion]];
		[self showAuthorizeNavigationViewController];
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	DLog(@"");
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	DLog(@"");
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	DLog(@"");
	
	if ([GHUserSettings resetAppOnStart])
	{
		[[GHOAuth2Controller sharedInstance] deleteAccessGrant];
		[GHUserSettings reset];
		[self showAuthorizeNavigationViewController];
	}	
	else if ([[GHOAuth2Controller sharedInstance] isAuthorized])
	{
		[self showTabBarController];
	}
	else 
	{
		[self showAuthorizeNavigationViewController];
	}
	
    [window makeKeyAndVisible];
	
	[GHUserSettings setAppVersion:[GHAppSettings appVersion]];
	[self verifyLocationServices];

	return;
}

- (void)applicationWillTerminate:(UIApplication *)application 
{    
	DLog(@"");
}

@end

