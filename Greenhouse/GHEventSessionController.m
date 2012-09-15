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
//  GHEventSessionController.m
//  Greenhouse
//
//  Created by Roy Clarkson on 9/7/10.
//

#import "GHEventSessionController.h"
#import "GHCoreDataManager.h"
#import "GHEventController.h"
#import "Event.h"
#import "EventSessionLeader.h"
#import "VenueRoom.h"

@implementation GHEventSessionController


#pragma mark -
#pragma mark Static methods

+ (GHEventSessionController *)sharedInstance
{
    static GHEventSessionController *_sharedInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _sharedInstance = [[GHEventSessionController alloc] init];
    });
    return _sharedInstance;
}


#pragma mark -
#pragma mark Fetch Current Sessions With Id

- (void)fetchCurrentSessionsWithEventId:(NSNumber *)eventId delegate:(id<GHEventSessionsCurrentDelegate>)delegate
{
    NSPredicate *predicate = [self predicateWithEventId:eventId date:[NSDate date]];
    NSArray *sessions = [self fetchSessionsWithPredicate:predicate];
    if (sessions.count > 0)
    {
        [delegate fetchCurrentSessionsDidFinishWithResults:sessions];
    }
    else
    {
        [self sendRequestForCurrentSessionsWithEventId:eventId delegate:delegate];
    }
}

- (void)sendRequestForCurrentSessionsWithEventId:(NSNumber *)eventId delegate:(id<GHEventSessionsCurrentDelegate>)delegate
{
	// request the sessions for the current day
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"YYYY-MM-d"];
    NSDate *now = [NSDate date];
	NSString *dateString = [dateFormatter stringFromDate:now];
	NSString *urlString = [[NSString alloc] initWithFormat:EVENT_SESSIONS_BY_DAY_URL, eventId, dateString];
	NSURL *url = [[NSURL alloc] initWithString:urlString];
	
    NSMutableURLRequest *request = [[GHAuthorizedRequest alloc] initWithURL:url];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	
	DLog(@"%@", request);
	
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data.length > 0 && error == nil)
         {
             DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
             NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
             NSArray *sessions = nil;
             if (!error)
             {
                 [self deleteSessionsWithEventId:eventId date:now];
                 [self storeSessionsWithEventId:eventId json:jsonArray];
                 NSPredicate *predicate = [self predicateWithEventId:eventId date:now];
                 sessions = [self fetchSessionsWithPredicate:predicate];
             }
             [delegate fetchCurrentSessionsDidFinishWithResults:sessions];
         }
         else if (error)
         {
             [self requestDidFailWithError:error];
             [delegate fetchCurrentSessionsDidFailWithError:error];
         }
         else if (statusCode != 200)
         {
             [self requestDidNotSucceedWithDefaultMessage:@"A problem occurred while retrieving the session data." response:response];
         }
     }];
}


#pragma mark -
#pragma mark Fetch Sessions With Id

- (void)fetchSessionsWithEventId:(NSNumber *)eventId date:(NSDate *)eventDate delegate:(id<GHEventSessionsByDateDelegate>)delegate
{
    NSPredicate *predicate = [self predicateWithEventId:eventId date:eventDate];
    NSArray *sessions = [self fetchSessionsWithPredicate:predicate];
    if (sessions.count > 0)
    {
        [delegate fetchSessionsByDateDidFinishWithResults:sessions];
    }
    else
    {
        [self sendRequestForSessionsWithEventId:eventId date:eventDate delegate:delegate];
    }
}

- (void)sendRequestForSessionsWithEventId:(NSNumber *)eventId date:(NSDate *)eventDate delegate:(id<GHEventSessionsByDateDelegate>)delegate
{
	// request the sessions for the selected day
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"YYYY-MM-d"];
	NSString *dateString = [dateFormatter stringFromDate:eventDate];
	NSString *urlString = [[NSString alloc] initWithFormat:EVENT_SESSIONS_BY_DAY_URL, eventId, dateString];
	NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSMutableURLRequest *request = [[GHAuthorizedRequest alloc] initWithURL:url];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	DLog(@"%@", request);
	
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data.length > 0 && error == nil)
         {
             DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
             NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
             NSArray *sessions = nil;
             if (!error)
             {
                 DLog(@"%@", jsonArray);
                 [self deleteSessionsWithEventId:eventId date:eventDate];
                 [self storeSessionsWithEventId:eventId json:jsonArray];
                 NSPredicate *predicate = [self predicateWithEventId:eventId date:eventDate];
                 sessions = [self fetchSessionsWithPredicate:predicate];
             }
             [delegate fetchSessionsByDateDidFinishWithResults:sessions];
         }
         else if (error)
         {
             [self requestDidFailWithError:error];
             [delegate fetchSessionsByDateDidFailWithError:error];
         }
         else if (statusCode != 200)
         {
             [self requestDidNotSucceedWithDefaultMessage:@"A problem occurred while retrieving the session data." response:response];
         }
     }];
}

- (EventSession *)fetchSessionWithNumber:(NSNumber *)number
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"number == %@", number];
    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EventSession" inManagedObjectContext:context];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    EventSession *session = nil;
    if (fetchedObjects && fetchedObjects.count > 0)
    {
        session = [fetchedObjects objectAtIndex:0];
    }
    return session;
}

- (NSArray *)fetchSessionsWithEventId:(NSString *)eventId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"event.eventId == %@", eventId];
    return [self fetchSessionsWithPredicate:predicate];
}

- (NSArray *)fetchSessionsWithPredicate:(NSPredicate *)predicate
{
    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EventSession" inManagedObjectContext:context];
    NSSortDescriptor *sortByStartTime = [[NSSortDescriptor alloc] initWithKey:@"startTime" ascending:YES];
    NSSortDescriptor *sortByTitle = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortByStartTime, sortByTitle, nil]];
    if (predicate)
    {
        [fetchRequest setPredicate:predicate];
    }
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    return fetchedObjects;
}

- (void)storeSessionsWithEventId:(NSNumber *)eventId json:(NSArray *)sessions
{
    DLog(@"");
    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
    Event *event = [[GHEventController sharedInstance] fetchEventWithId:eventId];
    [sessions enumerateObjectsUsingBlock:^(NSDictionary *sessionDict, NSUInteger idx, BOOL *stop) {
        EventSession *session = [NSEntityDescription
                        insertNewObjectForEntityForName:@"EventSession"
                        inManagedObjectContext:context];
        session.sessionId = [sessionDict objectForKey:@"id"];
        session.number = [sessionDict objectForKey:@"number"];
        session.title = [sessionDict stringByReplacingPercentEscapesForKey:@"title" usingEncoding:NSUTF8StringEncoding];
        session.startTime = [sessionDict dateWithMillisecondsSince1970ForKey:@"startTime"];
        session.endTime = [sessionDict dateWithMillisecondsSince1970ForKey:@"endTime"];
        session.information = [[sessionDict stringForKey:@"description"] stringByXMLDecoding];
        session.hashtag = [sessionDict stringByReplacingPercentEscapesForKey:@"hashtag" usingEncoding:NSUTF8StringEncoding];
        session.isFavorite = [NSNumber numberWithBool:[sessionDict boolForKey:@"favorite"]];
        session.rating = [NSNumber numberWithDouble:[sessionDict doubleForKey:@"rating"]];
        
        NSArray *leaders = [sessionDict objectForKey:@"leaders"];
        [leaders enumerateObjectsUsingBlock:^(NSDictionary *leaderDict, NSUInteger idx, BOOL *stop) {
            EventSessionLeader *leader = [NSEntityDescription
                                          insertNewObjectForEntityForName:@"EventSessionLeader"
                                          inManagedObjectContext:context];
            leader.firstName = [leaderDict objectForKey:@"firstName"];
            leader.lastName = [leaderDict objectForKey:@"lastName"];
            [session addLeadersObject:leader];
        }];
        
        NSDictionary *roomDict = [sessionDict objectForKey:@"room"];
        VenueRoom *room = [NSEntityDescription
                           insertNewObjectForEntityForName:@"VenueRoom"
                           inManagedObjectContext:context];
        room.roomId = [roomDict objectForKey:@"id"];
        room.label = [roomDict objectForKey:@"label"];
        session.room = room;
        
        [event addSessionsObject:session];
    }];
    
    NSError *error;
    [context save:&error];
    if (error)
    {
        DLog(@"%@", [error localizedDescription]);
    }
}

- (void)deleteSessionsWithEventId:(NSNumber *)eventId date:(NSDate *)date
{
    DLog(@"");
    NSPredicate *predicate = [self predicateWithEventId:eventId date:date];
    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
    NSArray *sessions = [self fetchSessionsWithPredicate:predicate];
    if (sessions)
    {
        [sessions enumerateObjectsUsingBlock:^(EventSession *session, NSUInteger idx, BOOL *stop) {
            [context deleteObject:session];
        }];
    }
    
    NSError *error;
    [context save:&error];
    if (error)
    {
        DLog(@"%@", [error localizedDescription]);
    }
}

- (NSPredicate *)predicateWithEventId:(NSNumber *)eventId date:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSUInteger units = (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSTimeZoneCalendarUnit);
    NSDateComponents *components = [calendar components:units fromDate:date];
    NSDate *startDate = [calendar dateFromComponents:components];
    components = [[NSDateComponents alloc] init];
    [components setDay:1];
    NSDate *endDate = [calendar dateByAddingComponents:components toDate:startDate options:0];
    DLog(@"startDate: %@", startDate);
    DLog(@"endDate: %@", endDate);
    return [NSPredicate predicateWithFormat:@"(event.eventId == %@) AND (startTime > %@) AND (startTime <= %@)", eventId, startDate, endDate];
}


#pragma mark -
#pragma mark Fetch Favorite Sessions

- (void)fetchFavoriteSessionsWithEventId:(NSNumber *)eventId delegate:(id<GHEventSessionsFavoritesDelegate>)delegate
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite == YES"];
    NSArray *sessions = [self fetchSessionsWithPredicate:predicate];
    [delegate fetchFavoriteSessionsDidFinishWithResults:sessions];
    [self sendRequestForFavoriteSessionsByEventId:eventId delegate:delegate];
}

- (void)sendRequestForFavoriteSessionsByEventId:(NSNumber *)eventId delegate:(id<GHEventSessionsFavoritesDelegate>)delegate
{
	NSString *urlString = [[NSString alloc] initWithFormat:EVENT_SESSIONS_FAVORITES_URL, eventId];
	NSURL *url = [[NSURL alloc] initWithString:urlString];
	
    NSMutableURLRequest *request = [[GHAuthorizedRequest alloc] initWithURL:url];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	DLog(@"%@", request);
	
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data.length > 0 && error == nil)
         {
             DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
             NSError *error;
             NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
             if (!error)
             {
                 [jsonArray enumerateObjectsUsingBlock:^(NSDictionary *jsonDict, NSUInteger idx, BOOL *stop) {
                     NSNumber *sessionNumber = [jsonDict objectForKey:@"number"];
                     EventSession *session = [self fetchSessionWithNumber:sessionNumber];
                     if (session)
                     {
                         session.isFavorite = [NSNumber numberWithBool:YES];
                     }
                 }];
                 NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
                 NSError *error;
                 [context save:&error];
                 if (error)
                 {
                     DLog(@"%@", [error localizedDescription]);
                 }
             }
             NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isFavorite == YES"];
             NSArray *sessions = [self fetchSessionsWithPredicate:predicate];
             [delegate fetchFavoriteSessionsDidFinishWithResults:sessions];
         }
         else if (error)
         {
//             [self requestDidFailWithError:error];
             [delegate fetchFavoriteSessionsDidFailWithError:error];
         }
         else if (statusCode != 200)
         {
//             [self requestDidNotSucceedWithDefaultMessage:@"A problem occurred while retrieving the session data." response:response];
         }
     }];
}


#pragma mark -
#pragma mark Fetch Conference Favorite Sessions

- (void)fetchConferenceFavoriteSessionsByEventId:(NSString *)eventId delegate:(id<GHEventSessionsConferenceFavoritesDelegate>)delegate
{
	NSString *urlString = [[NSString alloc] initWithFormat:EVENT_SESSIONS_CONFERENCE_FAVORITES_URL, eventId];
	NSURL *url = [[NSURL alloc] initWithString:urlString];
	
    NSMutableURLRequest *request = [[GHAuthorizedRequest alloc] initWithURL:url];
	[request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
	DLog(@"%@", request);
	
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data.length > 0 && error == nil)
         {
             DLog(@"%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
             
             NSError *error;
             NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
             NSMutableArray *arraySessions = [[NSMutableArray alloc] init];
             if (!error)
             {
                 DLog(@"%@", array);
                 // TODO: something
             }
             [delegate fetchConferenceFavoriteSessionsDidFinishWithResults:arraySessions];
         }
         else if (error)
         {
             [self requestDidFailWithError:error];
             [delegate fetchConferenceFavoriteSessionsDidFailWithError:error];
         }
         else if (statusCode != 200)
         {
             [self requestDidNotSucceedWithDefaultMessage:@"A problem occurred while retrieving the session data." response:response];
         }
     }];
}


#pragma mark -
#pragma mark Update Favorite Session

- (void)updateFavoriteSessionWithEventId:(NSNumber *)eventId sessionNumber:(NSNumber *)sessionNumber delegate:(id<GHEventSessionUpdateFavoriteDelegate>)delegate
{
    EventSession *session = [self fetchSessionWithNumber:sessionNumber];
    if (session)
    {
        session.isFavorite = [NSNumber numberWithBool:YES];
        NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
        NSError *error;
        [context save:&error];
        if (error)
        {
            DLog(@"%@", [error localizedDescription]);
        }
    }
    
    [self sendRequestToUpdateFavoriteSessionWithEventId:eventId sessionNumber:sessionNumber delegate:delegate];
}

- (void)sendRequestToUpdateFavoriteSessionWithEventId:(NSNumber *)eventId sessionNumber:(NSNumber *)sessionNumber delegate:(id<GHEventSessionUpdateFavoriteDelegate>)delegate
{	
	NSString *urlString = [[NSString alloc] initWithFormat:EVENT_SESSIONS_FAVORITE_URL, eventId, sessionNumber];
	NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSMutableURLRequest *request = [[GHAuthorizedRequest alloc] initWithURL:url];
	[request setHTTPMethod:@"PUT"];	
	DLog(@"%@", request);

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data.length > 0 && error == nil)
         {
             NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             DLog(@"%@", responseBody);
             [delegate updateFavoriteSessionDidFinishWithResults:[responseBody boolValue]];
         }
         else if (error)
         {
             [self requestDidFailWithError:error];
             [delegate updateFavoriteSessionDidFailWithError:error];
         }
         else if (statusCode != 200)
         {
             [self requestDidNotSucceedWithDefaultMessage:@"A problem occurred while updating the favorite." response:response];
         }
     }];
}


#pragma mark -
#pragma mark Rate Session

- (void)rateSession:(NSString *)sessionNumber withEventId:(NSString *)eventId rating:(NSInteger)rating comment:(NSString *)comment delegate:(id<GHEventSessionRateDelegate>)delegate
{
	self.activityAlertView = [[GHActivityAlertView alloc] initWithActivityMessage:@"Submitting rating..."];
	[_activityAlertView startAnimating];
	
	NSString *urlString = [[NSString alloc] initWithFormat:EVENT_SESSION_RATING_URL, eventId, sessionNumber];
	NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSMutableURLRequest *request = [[GHAuthorizedRequest alloc] initWithURL:url];
	
	NSString *trimmedComment = [comment stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *postParams =[[NSString alloc] initWithFormat:@"value=%i&comment=%@", rating, [trimmedComment stringByURLEncoding]];
	DLog(@"%@", postParams);
	NSData *putData = [postParams dataUsingEncoding:NSUTF8StringEncoding];
	NSString *putLength = [NSString stringWithFormat:@"%d", [putData length]];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	[request setValue:putLength forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:putData];
	
	DLog(@"%@", request);
	
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
     {
         [_activityAlertView stopAnimating];
         self.activityAlertView = nil;
         
         NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
         if (statusCode == 200 && data.length > 0 && error == nil)
         {
             NSString *responseBody = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             DLog(@"%@", responseBody);
             double rating = [responseBody doubleValue];
             [delegate rateSessionDidFinishWithResults:rating];
         }
         else if (error)
         {
             [self requestDidFailWithError:error];
             [delegate rateSessionDidFailWithError:error];
         }
         else if (statusCode != 200)
         {
             if (statusCode == 412)
             {
                 UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                     message:@"This session has not yet finished. Please wait until the session has completed before submitting your rating."
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
                 [alertView show];
             }
             else 
             {
                 [self requestDidNotSucceedWithDefaultMessage:@"A problem occurred while submitting the session rating." response:response];
             }
         }
     }];
}


#pragma mark -
#pragma mark Selected Session

#define KEY_SELECTED_SESSION_NUMBER @"selectedSessionNumber"

- (EventSession *)fetchSelectedSession
{
    NSNumber *sessionNumber = [[NSUserDefaults standardUserDefaults] objectForKey:KEY_SELECTED_SESSION_NUMBER];
    return [self fetchSessionWithNumber:sessionNumber];
}

- (void)setSelectedSession:(EventSession *)session
{
	[[NSUserDefaults standardUserDefaults] setObject:session.number forKey:KEY_SELECTED_SESSION_NUMBER];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#define KEY_SELECTED_SCHEDULE_DATE @"selectedScheduleDate"

- (NSDate *)fetchSelectedScheduleDate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:KEY_SELECTED_SCHEDULE_DATE];
}

- (void)setSelectedScheduleDate:(NSDate *)date
{
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:KEY_SELECTED_SCHEDULE_DATE];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

//- (EventSession *)fetchSelectedSession
//{
//    EventSession *session = nil;
//    NSManagedObjectContext *context = [[GHCoreDataManager sharedInstance] managedObjectContext];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"EventSession" inManagedObjectContext:context];
//    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isSelected == YES"];
//    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//    [fetchRequest setEntity:entity];
//    [fetchRequest setPredicate:predicate];
//    NSError *error;
//    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
//    if (fetchedObjects && fetchedObjects.count > 0)
//    {
//        session = [fetchedObjects objectAtIndex:0];
//    }
//    return session;
//}
//
//- (void)setSelectedSession:(EventSession *)session
//{
//    if (session)
//    {
//        NSArray *sessions = [self fetchSessionsWithPredicate:nil];
//        [sessions enumerateObjectsUsingBlock:^(EventSession *s, NSUInteger idx, BOOL *stop) {
//            BOOL isSelected = NO;
//            if ([s.number isEqualToNumber:session.number])
//            {
//                isSelected = YES;
//            }
//            s.isSelected = [NSNumber numberWithBool:isSelected];
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
