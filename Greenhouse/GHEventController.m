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
//  GHEventController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 8/31/10.
//

#import "GHEventController.h"
#import "GHCoreDataManager.h"
#import "Venue.h"

@implementation GHEventController


#pragma mark -
#pragma mark Static methods

// Use this class method to obtain the shared instance of the class.
+ (GHEventController *)sharedInstance
{
    static GHEventController *_sharedInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _sharedInstance = [[GHEventController alloc] init];
    });
    return _sharedInstance;
}


#pragma mark -
#pragma mark Instance methods

- (void)fetchEventsWithDelegate:(id<GHEventControllerDelegate>)delegate;
{
    NSArray *events = [self fetchEventsWithPredicate:nil];
    if (events.count > 0)
    {
        [delegate fetchEventsDidFinishWithResults:events];
    }
    else
    {
        [self sendRequestForEventsWithDelegate:delegate];
    }
}

- (NSArray *)fetchEventsWithPredicate:(NSPredicate *)predicate;
{
    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    if (predicate)
    {
        [fetchRequest setPredicate:predicate];
    }
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
}

- (void)sendRequestForEventsWithDelegate:(id<GHEventControllerDelegate>)delegate
{
	NSURL *url = [[NSURL alloc] initWithString:EVENTS_URL];
    NSMutableURLRequest *request = [[GHAuthorizedRequest alloc] initWithURL:url];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	DLog(@"%@", request);

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data.length > 0 && error == nil)
         {
             DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
             NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
             NSArray *events;
             if (!error)
             {
                 DLog(@"%@", jsonArray);
                 [self deleteEvents];
                 [self storeEventsWithJson:jsonArray];
                 events = [self fetchEventsWithPredicate:nil];
             }
             [delegate fetchEventsDidFinishWithResults:events];
         }
         else if (error)
         {
             [self requestDidFailWithError:error];
             [delegate fetchEventsDidFailWithError:error];
         }
         else if (statusCode != 200)
         {
             [self requestDidNotSucceedWithDefaultMessage:@"A problem occurred while retrieving the event data." response:response];
         }
     }];
}

- (void)storeEventsWithJson:(NSArray *)events
{
    DLog(@"");
    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
    [events enumerateObjectsUsingBlock:^(NSDictionary *eventDict, NSUInteger idx, BOOL *stop) {
        Event *event = [NSEntityDescription
                        insertNewObjectForEntityForName:@"Event"
                        inManagedObjectContext:context];
        event.eventId = [eventDict objectForKey:@"id"];
        event.title = [eventDict stringByReplacingPercentEscapesForKey:@"title" usingEncoding:NSUTF8StringEncoding];
        event.startTime = [eventDict dateWithMillisecondsSince1970ForKey:@"startTime"];
        event.endTime = [eventDict dateWithMillisecondsSince1970ForKey:@"endTime"];
        event.location = [eventDict stringByReplacingPercentEscapesForKey:@"location" usingEncoding:NSUTF8StringEncoding];
        event.information = [[eventDict stringForKey:@"description"] stringByXMLDecoding];
        event.hashtag = [eventDict stringByReplacingPercentEscapesForKey:@"hashtag" usingEncoding:NSUTF8StringEncoding];
        event.groupName = [eventDict stringByReplacingPercentEscapesForKey:@"groupName" usingEncoding:NSUTF8StringEncoding];
        event.timeZoneName = [[eventDict objectForKey:@"timeZone"] objectForKey:@"id"];
        
        NSArray *venues = [eventDict objectForKey:@"venues"];
        [venues enumerateObjectsUsingBlock:^(NSDictionary *venueDict, NSUInteger idx, BOOL *stop) {
            Venue *venue = [NSEntityDescription
                            insertNewObjectForEntityForName:@"Venue"
                            inManagedObjectContext:context];
            venue.venueId = [venueDict stringForKey:@"id"];
			venue.locationHint = [venueDict stringForKey:@"locationHint"];
			venue.postalAddress = [venueDict stringForKey:@"postalAddress"];
            venue.latitude = [[venueDict objectForKey:@"location"] objectForKey:@"latitude"];
            venue.longitude = [[venueDict objectForKey:@"location"] objectForKey:@"longitude"];
            [event addVenuesObject:venue];
        }];
    }];
    
    NSError *error;
    [context save:&error];
    if (error)
    {
//        DLog(@"%@", [error localizedDescription]);
        DumpError(@"save event", error);
    }
}

void DumpError(NSString* action, NSError* error) {
    
    if (!error)
        return;
    
    NSLog(@"Failed to %@: %@", action, [error localizedDescription]);
    NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if(detailedErrors && [detailedErrors count] > 0) {
        for(NSError* detailedError in detailedErrors) {
            NSLog(@"DetailedError: %@", [detailedError userInfo]);
        }
    }
    else {
        NSLog(@"%@", [error userInfo]);
    }
}

- (void)deleteEvents
{
    DLog(@"");
    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
    NSArray *events = [self fetchEventsWithPredicate:nil];
    if (events)
    {
        [events enumerateObjectsUsingBlock:^(id event, NSUInteger idx, BOOL *stop) {
            [context deleteObject:event];
        }];
    }
    
    NSError *error;
    [context save:&error];
    if (error)
    {
        DLog(@"%@", [error localizedDescription]);
    }
}

- (Event *)fetchEventWithId:(NSNumber *)eventId;
{
    Event *event = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"eventId == %@", eventId];
    NSArray *fetchedObjects = [self fetchEventsWithPredicate:predicate];
    if (fetchedObjects && fetchedObjects.count > 0)
    {
        event = [fetchedObjects objectAtIndex:0];
    }
    return event;
}

- (Event *)fetchSelectedEvent
{
    NSNumber *eventId = [[NSUserDefaults standardUserDefaults] objectForKey:@"selectedEventId"];
    return [self fetchEventWithId:eventId];
}

- (void)setSelectedEvent:(Event *)event
{
	[[NSUserDefaults standardUserDefaults] setObject:event.eventId forKey:@"selectedEventId"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

//- (Event *)fetchSelectedEvent
//{
//    Event *event = nil;
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isSelected == YES"];
//    NSArray *fetchedObjects = [self fetchEventsWithPredicate:predicate];
//    if (fetchedObjects && fetchedObjects.count > 0)
//    {
//        event = [fetchedObjects objectAtIndex:0];
//    }
//    return event;
//}
//
//- (void)setSelectedEvent:(Event *)event
//{
//    if (event)
//    {
//        NSArray *objects = [self fetchEventsWithPredicate:nil];
//        [objects enumerateObjectsUsingBlock:^(Event *e, NSUInteger idx, BOOL *stop) {
//            BOOL selected = NO;
//            if ([e.eventId isEqualToNumber:event.eventId])
//            {
//                selected = YES;
//            }
//            e.isSelected = [NSNumber numberWithBool:selected];
//        }];
//    }
//    
//    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
//    NSError *error;
//    [context save:&error];
//    if (error)
//    {
//        DLog(@"%@", [error localizedDescription]);
//    }
//}

@end
