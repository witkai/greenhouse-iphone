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
        event.eventId = [eventDict stringForKey:@"id"];
        event.title = [eventDict stringByReplacingPercentEscapesForKey:@"title" usingEncoding:NSUTF8StringEncoding];
        event.startTime = [eventDict dateWithMillisecondsSince1970ForKey:@"startTime"];
        event.endTime = [eventDict dateWithMillisecondsSince1970ForKey:@"endTime"];
        event.location = [eventDict stringByReplacingPercentEscapesForKey:@"location" usingEncoding:NSUTF8StringEncoding];
        event.information = [[eventDict stringForKey:@"description"] stringByXMLDecoding];
        event.name = [eventDict stringByReplacingPercentEscapesForKey:@"name" usingEncoding:NSUTF8StringEncoding];
        event.hashtag = [eventDict stringByReplacingPercentEscapesForKey:@"hashtag" usingEncoding:NSUTF8StringEncoding];
        event.groupName = [eventDict stringByReplacingPercentEscapesForKey:@"groupName" usingEncoding:NSUTF8StringEncoding];
        
        NSArray *venues = [eventDict objectForKey:@"venues"];
        [venues enumerateObjectsUsingBlock:^(NSDictionary *venueDict, NSUInteger idx, BOOL *stop) {
            Venue *venue = [NSEntityDescription
                            insertNewObjectForEntityForName:@"Venue"
                            inManagedObjectContext:context];
            venue.venueId = [venueDict stringForKey:@"id"];
			venue.locationHint = [venueDict stringForKey:@"locationHint"];
			venue.name = [venueDict stringForKey:@"name"];
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
        DLog(@"%@", [error localizedDescription]);
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

- (Event *)fetchEventWithId:(NSString *)eventId;
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
    Event *event = nil;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"selected == YES"];
    NSArray *fetchedObjects = [self fetchEventsWithPredicate:predicate];
    if (fetchedObjects && fetchedObjects.count > 0)
    {
        event = [fetchedObjects objectAtIndex:0];
    }
    return event;
}

- (void)setSelectedEvent:(Event *)event
{
    if (event)
    {
        NSArray *objects = [self fetchEventsWithPredicate:nil];
        [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSManagedObject *o = (NSManagedObject *)obj;
            BOOL selected = NO;
            if ([[o valueForKey:@"eventId"] isEqualToString:event.eventId])
            {
                selected = YES;
            }
            [(NSManagedObject *)obj setValue:[NSNumber numberWithBool:selected] forKey:@"selected"];
        }];
    }
    
    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
    NSError *error;
    [context save:&error];
    if (error)
    {
        DLog(@"%@", [error localizedDescription]);
    }
}

//- (NSArray *)loadEventsFromDictionaryArray:(NSArray *)array
//{
//    NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:[array count]];
//    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        GHEvent *event = [self loadEventFromDictionary:obj];
//        [events addObject:event];
//    }];
//    return events;
//}
//
//- (GHEvent *)loadEventFromDictionary:(NSDictionary *)dictionary
//{
//    GHEvent *event = nil;
//    if (dictionary)
//    {
//        NSString *eventId = [dictionary stringForKey:@"id"];
//        NSString *title = [dictionary stringByReplacingPercentEscapesForKey:@"title" usingEncoding:NSUTF8StringEncoding];
//        NSDate *startTime = [dictionary dateWithMillisecondsSince1970ForKey:@"startTime"];
//        NSDate *endTime = [dictionary dateWithMillisecondsSince1970ForKey:@"endTime"];
//        NSString *location = [dictionary stringByReplacingPercentEscapesForKey:@"location" usingEncoding:NSUTF8StringEncoding];
//        NSString *description = [[dictionary stringForKey:@"description"] stringByXMLDecoding];
//        NSString *name = [dictionary stringByReplacingPercentEscapesForKey:@"name" usingEncoding:NSUTF8StringEncoding];
//        NSString *hashtag = [dictionary stringByReplacingPercentEscapesForKey:@"hashtag" usingEncoding:NSUTF8StringEncoding];
//        NSString *groupName = [dictionary stringByReplacingPercentEscapesForKey:@"groupName" usingEncoding:NSUTF8StringEncoding];
//        NSArray *venues = nil; // [self processVenueData:[dictionary objectForKey:@"venues"]]];
//        
//        event = [[GHEvent alloc] initWithEventId:eventId
//                                           title:title
//                                       startTime:startTime
//                                         entTime:endTime
//                                        location:location
//                                     description:description
//                                            name:name
//                                         hashtag:hashtag
//                                       groupName:groupName
//                                          venues:venues];
//    }
//    return event;
//}
//
//- (NSArray *)loadEventsFromManagedObjects:(NSArray *)objects
//{
//    NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:[objects count]];
//    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//        GHEvent *event = [self loadEventFromManagedObject:obj];
//        [events addObject:event];
//    }];
//    return events;
//}
//
//- (GHEvent *)loadEventFromManagedObject:(NSManagedObject *)object
//{
//    GHEvent *event = nil;
//    if (object)
//    {
//        NSString *eventId = [object valueForKey:@"eventId"];
//        NSString *title = [object valueForKey:@"title"];
//        //        double startMillis = [[(NSNumber *)object valueForKey:@"startTime"] doubleValue];
//        //        NSDate *startTime = [[NSDate alloc] initWithTimeIntervalSince1970:startMillis];
//        NSDate *startTime = [object valueForKey:@"startTime"];
//        //        double endMillis = [[(NSNumber *)object valueForKey:@"endTime"] doubleValue];
//        //        NSDate *endTime = [[NSDate alloc] initWithTimeIntervalSince1970:endMillis];
//        NSDate *endTime = [object valueForKey:@"endTime"];
//        NSString *location = [object valueForKey:@"location"];
//        NSString *description = [object valueForKey:@"information"];
//        NSString *name = [object valueForKey:@"name"];
//        NSString *hashtag = [object valueForKey:@"hashtag"];
//        NSString *groupName = [object valueForKey:@"groupName"];
//        NSArray *venues = nil;
//        
//        event = [[GHEvent alloc] initWithEventId:eventId
//                                           title:title
//                                       startTime:startTime
//                                         entTime:endTime
//                                        location:location
//                                     description:description
//                                            name:name
//                                         hashtag:hashtag
//                                       groupName:groupName
//                                          venues:venues];
//    }
//    return event;
//}

@end
